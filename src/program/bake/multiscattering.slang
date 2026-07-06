/*
    Some code from this file is taken and/or referenced from "Production Sky Rendering" at https://www.shadertoy.com/view/slSXRW,
    which is an implementation of "A Scalable and Production Ready Sky and Atmosphere Rendering Technique", Hillaire (2020).

    Minimal code changes; modified for my use case. The original shadertoy code was released under the MIT License.
*/

import lib.atmosphere;
import lib.math;

extern static const uint multiscatteringTextureWidth; 
extern static const uint multiscatteringTextureHeight; 

Texture2D transmittanceLookupTexture;
RWTexture2D<float4> multiscatteringLookupTexture;

// Generates the multiple-scattering LUT. Each pixel coordinate corresponds to a height and sun zenith angle, and
// the value is the multiple scattering approximation (Psi_ms from the paper, Eq. 10).
static const float mulScattSteps = 40.0;
static const int sqrtSamples = 16;

float3 getSphericalDir(float theta, float phi) {
    float cosPhi = cos(phi);
    float sinPhi = sin(phi);
    float cosTheta = cos(theta);
    float sinTheta = sin(theta);
    return float3(sinPhi * sinTheta, cosPhi, sinPhi * cosTheta);
}

// Calculates Equation (5) and (7) from the paper.
void getMulScattValues(float3 pos, float3 sunDir, out float3 lumTotal, out float3 fms) {
    lumTotal = float3(0.0);
    fms = float3(0.0);

    float invSamples = 1.0 / float(sqrtSamples * sqrtSamples);
    for (int i = 0; i < sqrtSamples; i++) {
        for (int j = 0; j < sqrtSamples; j++) {
            // This integral is symmetric about theta = 0 (or theta = PI), so we
            // only need to integrate from zero to PI, not zero to 2*PI.
            float theta = PI * (float(i) + 0.5) / float(sqrtSamples);
            float phi = acos(clamp(1.0 - 2.0 * (float(j) + 0.5) / float(sqrtSamples), -1.0, 1.0));
            float3 rayDir = getSphericalDir(theta, phi);

            float atmoDist = rayIntersectSphere(pos, rayDir, atmosphereRadiusMM);
            float groundDist = rayIntersectSphere(pos, rayDir, groundRadiusMM);
            float tMax = atmoDist;
            if (groundDist > 0.0) {
                tMax = groundDist;
            }

            float cosTheta = dot(rayDir, sunDir);

            float miePhaseValue = getMiePhase(cosTheta);
            float rayleighPhaseValue = getRayleighPhase(-cosTheta);

            float3 lum = float3(0.0), lumFactor = float3(0.0), transmittance = float3(1.0);
            float t = 0.0;
            for (float stepI = 0.0; stepI < mulScattSteps; stepI += 1.0) {
                float newT = ((stepI + 0.3) / mulScattSteps) * tMax;
                float dt = newT - t;
                t = newT;

                float3 newPos = pos + t * rayDir;

                float3 rayleighScattering, extinction;
                float mieScattering;
                getScatteringValues(newPos, rayleighScattering, mieScattering, extinction);

                float3 sampleTransmittance = exp(-dt * extinction);

                // Integrate within each segment.
                float3 scatteringNoPhase = rayleighScattering + mieScattering;
                float3 scatteringF = (scatteringNoPhase - scatteringNoPhase * sampleTransmittance) / extinction;
                lumFactor += transmittance * scatteringF;

                // This is slightly different from the paper, but I think the paper has a mistake?
                // In equation (6), I think S(x,w_s) should be S(x-tv,w_s).
                float3 sunTransmittance = getValFromTLUT(transmittanceLookupTexture, newPos, sunDir);

                float3 rayleighInScattering = rayleighScattering * rayleighPhaseValue;
                float mieInScattering = mieScattering * miePhaseValue;
                float3 inScattering = (rayleighInScattering + mieInScattering) * sunTransmittance;

                // Integrated scattering within path segment.
                float3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

                lum += scatteringIntegral * transmittance;
                transmittance *= sampleTransmittance;
            }

            if (groundDist > 0.0) {
                float3 hitPos = pos + groundDist * rayDir;
                if (dot(pos, sunDir) > 0.0) {
                    hitPos = normalize(hitPos) * groundRadiusMM;
                    lum += transmittance * groundAlbedo * getValFromTLUT(transmittanceLookupTexture, hitPos, sunDir);
                }
            }

            fms += lumFactor * invSamples;
            lumTotal += lum * invSamples;
        }
    }
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void multiscattering(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(multiscatteringTextureWidth, multiscatteringTextureHeight);

    float sunCosTheta = 2.0 * uv.x - 1.0;
    float sunTheta = acos(clamp(sunCosTheta, -1.0, 1.0));
    float height = lerp(groundRadiusMM + 1e-6, atmosphereRadiusMM, uv.y);

    float3 pos = float3(0.0, height, 0.0);
    float3 sunDir = normalize(float3(0.0, sunCosTheta, -sin(sunTheta)));

    float3 lum, f_ms;
    getMulScattValues(pos, sunDir, lum, f_ms);

    // Equation 10 from the paper.
    float3 psi = lum / (1.0 - f_ms);

    multiscatteringLookupTexture.Store(globalInvocationId.xy, float4(psi, 1.0));
}
