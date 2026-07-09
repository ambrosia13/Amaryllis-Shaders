public module util;

import aperture;

public float3 getSunVector() {
    return normalize(mul(ap.camera.viewInv, float4(ap.celestial.sunPosition, 1.0)).xyz);
}

public float3 getMoonVector() {
    return -getSunVector();
    // return normalize(mul(ap.camera.viewInv, float4(ap.celestial.moonPosition, 1.0)).xyz);
}

public float3 getLightVector() {
    float3 sunVector = getSunVector();
    return sunVector * sign(sunVector.y);
}
