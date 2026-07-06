public module util;

import aperture;

public float3 getSunVector() {
    return normalize(mul(ap.camera.viewInv, float4(ap.celestial.sunPosition, 1.0)).rgb);
}

public float3 getMoonVector() {
    return normalize(mul(ap.camera.viewInv, float4(ap.celestial.moonPosition, 1.0)).rgb);
}

public vector<float, N> pow2<uint N>(vector<float, N> x) { 
    return x * x; 
}


