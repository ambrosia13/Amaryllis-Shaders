/*
    Most code from this file is taken and/or referenced from "Production Sky Rendering" at https://www.shadertoy.com/view/slSXRW,
    which is an implementation of "A Scalable and Production Ready Sky and Atmosphere Rendering Technique", Hillaire (2020).

    Minimal code changes; modified for my use case. The original shadertoy code was released under the MIT License.
*/

public module atmosphere;

import aperture;

import lib.util;
import lib.math;

// Units are in megameters.
static const float groundRadiusMM = 6.360;
static const float atmosphereRadiusMM = 6.460;

static const float3 groundAlbedo = float3(0.3);

// Units are per-megameter
static const float3 rayleighScatteringBase = float3(5.802, 13.558, 33.1);
static const float rayleighAbsorptionBase = 0.0;

static const float mieScatteringBase = 25.996;
static const float mieAbsorptionBase = 4.4;

static const float3 ozoneAbsorptionBase = float3(0.650, 1.881, 0.085);

// One minecraft block is equivalent to this many meters in the atmosphere
public static const float minecraftToAtmosphereUnitScale = 25.0;

public float3 getAtmosphereViewingPos() {
    // position starts at 500M above the ground
    float elevation = 500.0 + max(0.0, ap.camera.position.y - 100.0) * minecraftToAtmosphereUnitScale;
    return float3(0.0, groundRadiusMM + 1e-6 * elevation, 0.0);
}

// Phase function from Jessie
// https://www.patreon.com/user?u=49201970
float kleinNishinaPhase(float cosTheta, float g) {
    float e = 1.0;
    for (int i = 0; i < 8; ++i) {
        float logE = log(2.0 * e + 1.0);
        float gFromE = 1.0 / e - 2.0 / logE + 1.0;
        float deriv = 4.0 / ((2.0 * e + 1.0) * pow2(logE)) - 1.0 / pow2(e);
        if (abs(deriv) < 0.00000001) break;
        e = e - (gFromE - g) / deriv;
    }

    return e / (2.0 * PI * (e * (1.0 - cosTheta) + 1.0) * log(2.0 * e + 1.0));
}

public float getMiePhase(float cosTheta) {
    // default atmosphere-accurate mie phase value (todo: find source?)
    return kleinNishinaPhase(cosTheta, 0.76385);
}

public float getMiePhase(float cosTheta, float g) {
    return kleinNishinaPhase(cosTheta, g);
}

float getRayleighPhase(float cosTheta) {
    return 0.05968310365 * (1.0 + cosTheta * cosTheta);
}

void getScatteringValues(
    float3 pos,
    out float3 rayleighScattering,
    out float mieScattering,
    out float3 extinction
) {
    float altitudeKM = (length(pos) - groundRadiusMM) * 1000.0;

    // Note: Paper gets these switched up.
    float rayleighDensity = exp(-altitudeKM / 8.0);
    float mieDensity = exp(-altitudeKM / 1.2);

    rayleighScattering = rayleighScatteringBase * rayleighDensity;
    float rayleighAbsorption = rayleighAbsorptionBase * rayleighDensity;

    mieScattering = mieScatteringBase * mieDensity;
    float mieAbsorption = mieAbsorptionBase * mieDensity;

    float3 ozoneAbsorption = ozoneAbsorptionBase * max(0.0, 1.0 - abs(altitudeKM - 25.0) / 15.0);

    extinction = rayleighScattering + rayleighAbsorption + mieScattering + mieAbsorption + ozoneAbsorption;
}

// From https://gamedev.stackexchange.com/questions/96459/fast-ray-sphere-collision-code.
public float rayIntersectSphere(float3 ro, float3 rd, float rad) {
    float b = dot(ro, rd);
    float c = dot(ro, ro) - rad * rad;
    if (c > 0.0 && b > 0.0) return -1.0;
    float discr = b * b - c;
    if (discr < 0.0) return -1.0;
    // Special case: inside sphere, use far discriminant
    if (discr > b * b) return (-b + sqrt(discr));
    return -b - sqrt(discr);
}

public float3 getValFromTLUT(Texture2D tex, float3 pos, float3 sunDir) {
    float height = length(pos);
    float3 up = pos / height;
    float sunCosZenithAngle = dot(sunDir, up);
    float2 uv = float2(clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
            max(0.0, min(1.0, (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM))));

    return tex.Sample(apt_linearSampler, uv).rgb;
}

float3 getValFromMultiScattLUT(Texture2D tex, float3 pos, float3 sunDir) {
    float height = length(pos);
    float3 up = pos / height;
    float sunCosZenithAngle = dot(sunDir, up);
    float2 uv = float2(clamp(0.5 + 0.5 * sunCosZenithAngle, 0.0, 1.0),
            max(0.0, min(1.0, (height - groundRadiusMM) / (atmosphereRadiusMM - groundRadiusMM))));

    return tex.Sample(apt_linearSampler, uv).rgb;
}

// Calculates the actual sky-view! It's a lat-long map (or maybe altitude-azimuth is the better term),
// but the latitude/altitude is non-linear to get more resolution near the horizon.
public float3 raymarchScattering(
    Texture2D transmittanceLut,
    Texture2D multiscatteringLut,
    float3 pos,
    float3 rayDir,
    float3 sunDir,
    float3 sunColor,
    float mieScatteringAmount,
    float tMax,
    int numSteps,
    out float3 transmittance,
) {
    float cosTheta = dot(rayDir, sunDir);

    float miePhaseValue = getMiePhase(cosTheta);
    float rayleighPhaseValue = getRayleighPhase(-cosTheta);

    float3 lum = float3(0.0);
    transmittance = float3(1.0);

    float t = 0.0;

    for (int i = 0; i < numSteps; i += 1) {
        float newT = ((float(i) + 0.3) / numSteps) * tMax;
        float dt = newT - t;
        t = newT;

        float3 newPos = pos + t * rayDir;

        float3 rayleighScattering, extinction;
        float mieScattering;
        getScatteringValues(newPos, rayleighScattering, mieScattering, extinction);

        float3 sampleTransmittance = exp(-dt * extinction);

        float3 sunTransmittance = getValFromTLUT(transmittanceLut, newPos, sunDir) * sunColor;
        float3 psiMS = getValFromMultiScattLUT(multiscatteringLut, newPos, sunDir);

        float3 rayleighInScattering = rayleighScattering * (rayleighPhaseValue * sunTransmittance + psiMS);
        float3 mieInScattering = mieScattering * (miePhaseValue * sunTransmittance + psiMS);
        float3 inScattering = (rayleighInScattering + mieInScattering * mieScatteringAmount);

        // Integrated scattering within path segment.
        float3 scatteringIntegral = (inScattering - inScattering * sampleTransmittance) / extinction;

        lum += scatteringIntegral * transmittance;

        transmittance *= sampleTransmittance;
    }

    return lum;
}

float3 getValFromSkyLUT(Texture2D skyLut, float3 rayDir, float3 sunDir, float lod) {
    float3 skyViewPos = getAtmosphereViewingPos();

    float height = length(skyViewPos);
    float3 up = skyViewPos * rcp(height);

    float horizonAngle = acos(clamp(sqrt(height * height - groundRadiusMM * groundRadiusMM) / height, -1.0, 1.0));
    float altitudeAngle = horizonAngle - acos(dot(rayDir, up)); // Between -PI/2 and PI/2
    float azimuthAngle; // Between 0 and 2*PI
    if (abs(altitudeAngle) > (HALF_PI - .0001)) {
        // Looking nearly straight up or down.
        azimuthAngle = 0.0;
    } else {
        float3 right = cross(sunDir, up);
        float3 forward = cross(up, right);

        // note from ambrosia13: the normalize here is not actually needed, since atan2 takes the ratio between the two.
        // so avoiding this normalization fixes some numerical instability
        float3 projectedDir = (rayDir - up * (dot(rayDir, up)));
        float sinTheta = dot(projectedDir, right);
        float cosTheta = dot(projectedDir, forward);
        azimuthAngle = atan2(sinTheta, cosTheta) + PI;
    }

    // Non-linear mapping of altitude angle. See Section 5.3 of the paper.
    float v = 0.5 + 0.5 * sign(altitudeAngle) * sqrt(abs(altitudeAngle) * 2.0 / PI);
    float2 uv = float2(azimuthAngle / (TAU), v);

    return skyLut.SampleLevel(apt_linearSampler, uv, lod).rgb;
}

float3 getValFromSkyLUT(Texture2D skyLut, float3 rayDir, float3 sunDir) {
    return getValFromSkyLUT(skyLut, rayDir, sunDir, 0);
}

