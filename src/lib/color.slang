// see https://github.com/vram-guild/frex/blob/1.19/common/src/main/resources/assets/frex/shaders/lib/math.glsl
public float luminance(float3 color) {
    return dot(color.rgb, float3(0.299, 0.587, 0.114));
}

public float3 normalizeLuminance(float3 color) {
    return color / luminance(color);
}

/*
    Provided by LuRa in the shaderLABS discord server #snippets.
*/
public float3 linearizeSrgb(float3 srgb) {
    return select(
        srgb <= float3(0.04045),
        srgb / 12.92,
        pow((srgb + 0.055) / 1.055, float3(2.4)),
    );
}

/*
    Provided by LuRa in the shaderLABS discord server #snippets.
*/
public float3 gammaCorrectSrgb(float3 linear) {
    return select(
        linear <= float3(0.0031308),
        12.92 * linear,
        1.055 * pow(linear, float3(1.0 / 2.4)) - 0.055,
    );
}

public float3 srgbToAcesCg(float3 srgb) {
    const float3x3 sRGBtoAP1 = float3x3(
        0.613097, 0.339523, 0.047379,
        0.070194, 0.916354, 0.013452,
        0.020616, 0.109570, 0.869815
    );

    return mul(sRGBtoAP1, srgb);
}

public float3 acesCgToSrgb(float3 acesCg) {
    const float3x3 AP1toSRGB = float3x3(
        1.704859, -0.621715, -0.083299,
        -0.130078,  1.140734, -0.010560,
        -0.023964, -0.128975,  1.153013
    );

    return mul(AP1toSRGB, acesCg);
}

/*
    From Emi_V7 in the shaderLABS discord server #snippets.
*/
public float3 purkinjeShift(float3 rgb) {
    const float4x3 rgb_to_lmsr = float4x3(
        7.69684945, 18.4248204, 2.06809497,
        2.43113687, 18.6979422, 3.01246326,
        0.28911757, 1.40183293, 13.7922962,
        0.46638595, 15.5643680, 10.0599647
    );

    const float3x3 lms_gain_to_rgb = float3x3( // good enough
         1.0, -0.1, -0.2,
        -0.8,  0.4, -0.3,
        -0.2,  0.0,  1.7
    );

    float4 lmsr = mul(rgb_to_lmsr, rgb);
    float3 lms_gain = 1.0 / sqrt(1.0 + lmsr.xyz);
    return rgb + mul(lms_gain, lms_gain_to_rgb) * (lmsr.w * 0.05);
}

