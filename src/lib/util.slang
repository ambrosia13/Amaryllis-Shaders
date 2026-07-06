public module util;

import aperture;

public float3 getSunVector() {
    return normalize(mul(ap.camera.viewInv, float4(ap.celestial.sunPosition, 1.0)).xyz);
}

public float3 getMoonVector() {
    return -getSunVector();
    // return normalize(mul(ap.camera.viewInv, float4(ap.celestial.moonPosition, 1.0)).xyz);
}

public vector<float, N> pow2<uint N>(vector<float, N> x) { 
    return x * x; 
}

// see https://github.com/vram-guild/frex/blob/1.19/common/src/main/resources/assets/frex/shaders/lib/math.glsl
public float luminance(float3 color) {
    return dot(color.rgb, float3(0.299, 0.587, 0.114));
}
