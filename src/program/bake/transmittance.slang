/*
    Some code from this file is taken and/or referenced from "Production Sky Rendering" at https://www.shadertoy.com/view/slSXRW,
    which is an implementation of "A Scalable and Production Ready Sky and Atmosphere Rendering Technique", Hillaire (2020).

    Minimal code changes; modified for my use case. The original shadertoy code was released under the MIT License.
*/

import lib.atmosphere;

extern static const uint transmittanceTextureWidth; 
extern static const uint transmittanceTextureHeight; 

RWTexture2D<float4> transmittanceLookupTexture;

// Generates the Transmittance LUT. Each pixel coordinate corresponds to a height and sun zenith angle, and
// the value is the transmittance from that point to sun, through the atmosphere.
static const float sunTransmittanceSteps = 80.0;

float3 getSunTransmittance(float3 pos, float3 sunDir) {
    if (rayIntersectSphere(pos, sunDir, groundRadiusMM) > 0.0) {
        return float3(0.0);
    }

    float atmoDist = rayIntersectSphere(pos, sunDir, atmosphereRadiusMM);
    float t = 0.0;

    float3 transmittance = float3(1.0);
    for (float i = 0.0; i < sunTransmittanceSteps; i += 1.0) {
        float newT = ((i + 0.3) / sunTransmittanceSteps) * atmoDist;
        float dt = newT - t;
        t = newT;

        float3 newPos = pos + t * sunDir;

        float3 rayleighScattering, extinction;
        float mieScattering;
        getScatteringValues(newPos, rayleighScattering, mieScattering, extinction);

        transmittance *= exp(-dt * extinction);
    }

    return transmittance;
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void transmittance(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(transmittanceTextureWidth, transmittanceTextureHeight);

    float sunCosTheta = 2.0 * uv.x - 1.0;
    float sunTheta = acos(clamp(sunCosTheta, -1.0, 1.0));
    float height = lerp(groundRadiusMM + 1e-6, atmosphereRadiusMM, uv.y);

    float3 pos = float3(0.0, height, 0.0);
    float3 sunDir = normalize(float3(0.0, sunCosTheta, -sin(sunTheta)));

    transmittanceLookupTexture.Store(globalInvocationId.xy, float4(getSunTransmittance(pos, sunDir), 1.0));
}
