public module shadows; // Declare this is a module that can be imported.

import aperture;

extern static const int CASCADE_COUNT; // See `exportInt` in the Java.

// Please. Rewrite this. This is just a poor example.
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

static float shadowVisibility(float3 worldRelative) {
    uint cascadeCount = min(CASCADE_COUNT, max(1u, ap.celestial.cascadeCount));
    float4 lightView = mul(ap.celestial.view, float4(worldRelative, 1.0));

    float2 uv;
    float depth;
    for (uint cascade = 0; cascade < CASCADE_COUNT; cascade++) {
        if (projectShadow(lightView, cascade, uv, depth)) {
            return ap.opaqueShadow.compare(uv, int(cascade), depth - 0.0005);
        }
    }

    return 1.0;
}