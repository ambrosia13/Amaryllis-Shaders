public module shadows;

import aperture;

import lib.util;
import lib.math;
import lib.random;
import lib.material;

extern static const int shadowMapSize;

public float4 setupShadowViewSpacePos(float3 sceneSpacePos, float distance, float3 normalBias) {
    // variable bias based on distance
    // TODO: find a better heuristic
    sceneSpacePos += normalBias * (0.05 + 0.9 * (1.0 - exp(-distance * 0.01)));
    return mul(ap.celestial.view, float4(sceneSpacePos, 1.0));
}

bool projectShadow(float4 shadowViewSpacePos, uint cascade, out float3 shadowScreenSpacePos) {
    float4 clip = mul(ap.celestial.projection[cascade], shadowViewSpacePos);

    if (!isfinite(clip.w) || abs(clip.w) < 0.00001) {
        return false;
    }

    float3 ndc = clip.xyz / clip.w;
    shadowScreenSpacePos = float3(ndc.xy * 0.5 + 0.5, ndc.z);
    return all(shadowScreenSpacePos >= 0.0 && shadowScreenSpacePos <= 1.0);
}

// float blockerSearch()

public uint selectShadowCascade(
    float4 shadowViewSpacePos,
    out float3 shadowScreenSpacePos
) {
    uint cascadeCount = max(1u, ap.celestial.cascadeCount);

    for (uint cascade = 0; cascade < cascadeCount; cascade++) {
        if (projectShadow(shadowViewSpacePos, cascade, shadowScreenSpacePos)) {
            return cascade;
        }
    }

    return uint.maxValue;
}

public float shadowVisibility<bool filter, R: Rng>(
    inout Random<R> random, 
    uint cascade,
    float3 shadowScreenSpacePos,
    float basePenumbraSize, 
    uint samples,
    out bool outOfBounds,
) {
    outOfBounds = cascade == uint.maxValue;
    if (outOfBounds) return 1.0;

    float sampledShadowDepth = ap.opaqueShadow.sampleNearest(shadowScreenSpacePos.xy, cascade);
    if (sampledShadowDepth == 1.0) {
        outOfBounds = true;
        return 1.0;
    }

    // ensures resolutions less than 2048x have the same perceptual sharpness,
    // but resolutions greater than 2048x are blueed less to achieve even more sharpness
    float shadowSampleOffsetFactor = shadowMapSize < 2048 ? 1024 : float(shadowMapSize); 
    
    float shadow = 0.0;
    
    if (filter) {
        const float blockerSearchRangeMultiplier = 2.0; // take samples with twice the range for blocker search than for final filtering
    
        // I know not pcss for now, but let's ignore that
        for (uint i = 0; i < samples; i++) {
            float2 sampleOffset = diskSampling(i, samples, sqrt(random.getFloat() * TAU)) * basePenumbraSize / shadowSampleOffsetFactor;
            shadow += ap.opaqueShadow.compare(shadowScreenSpacePos.xy + sampleOffset, int(cascade), shadowScreenSpacePos.z - 5e-5) / samples;

        }
    } else {
        shadow = ap.opaqueShadow.compare(shadowScreenSpacePos.xy, cascade, shadowScreenSpacePos.z - 5e-5);
    }

    return shadow;
}