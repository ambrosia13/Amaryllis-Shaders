public module shadows;

import aperture;

import lib.util;
import lib.math;
import lib.random;
import lib.material;

extern static const int shadowCascadeCount;
extern static const int shadowMapSize;

static bool projectShadow(float4 lightView, uint cascade, out float2 uv, out float depth) {
    float4 clip = mul(ap.celestial.projection[cascade], lightView);

    if (!isfinite(clip.w) || abs(clip.w) < 0.00001) {
        return false;
    }

    float3 ndc = clip.xyz / clip.w;
    uv = ndc.xy * 0.5 + 0.5;
    depth = ndc.z;
    float3 shadowPos = float3(uv, depth);
    return all(shadowPos >= 0.0 && shadowPos <= 1.0);
}

static float shadowVisibility(int2 coord, float3 sceneSpacePos, float distance, Material mat) {
    uint cascadeCount = min(shadowCascadeCount, max(1u, ap.celestial.cascadeCount));

    // variable bias based on distance
    // TODO: find a better heuristic
    sceneSpacePos += mat.vertexNormal * (0.05 + 0.9 * (1.0 - exp(-distance * 0.01)));
    float4 shadowViewSpacePos = mul(ap.celestial.view, float4(sceneSpacePos, 1.0));

    const float shadowSampleOffsetFactor = 1024.0; // ensures consistent perceptual shadow softness across different shadow resolutions
    const float blockerSearchRangeMultiplier = 2.0; // take samples with twice the range for blocker search than for final filtering
    const uint shadowFilterSamples = 4; // 4 is good enough for small constant penumbra size

    // the back faces of subsurface scattering materials should have a wider penumbra to give the "diffused" look
    float basePenumbraSize = 1.0 + 4.0 * mat.sssAmount * float(dot(mat.vertexNormal, getLightVector()) < 0.0);

    // Ign ign = Ign(coord, ap.timing.frameCounter);
    Random<Ign> random = Random<Ign>(Ign(coord, ap.timing.frameCounter));

    float2 uv;
    float depth;
    for (uint cascade = 0; cascade < shadowCascadeCount; cascade++) {
        if (projectShadow(shadowViewSpacePos, cascade, uv, depth)) {
            float shadow = 0.0;
            
            for (uint i = 0; i < shadowFilterSamples; i++) {
                float2 sampleOffset = diskSampling(i, shadowFilterSamples, sqrt(random.getFloat() * TAU)) * basePenumbraSize / shadowSampleOffsetFactor;
                shadow += ap.opaqueShadow.compare(uv + sampleOffset, int(cascade), depth - 5e-5) / shadowFilterSamples;

            }

            return shadow;
        }
    }

    return 1.0;
}