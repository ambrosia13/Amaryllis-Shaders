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
public float3 toLinear(float3 srgb) {
    return select(
        srgb <= float3(0.04045),
        srgb / 12.92,
        pow((srgb + 0.055) / 1.055, float3(2.4)),
    );
}

/*
    Provided by LuRa in the shaderLABS discord server #snippets.
*/
public float3 toSrgb(float3 linear) {
    return select(
        linear <= float3(0.0031308),
        12.92 * linear,
        1.055 * pow(linear, float3(1.0 / 2.4)) - 0.055,
    );
}

/*
    The following four functions are FREX adaptations for common aces fit tone mapping:
    https://github.com/vram-guild/frex/blob/1.19/common/src/main/resources/assets/frex/shaders/lib/color.glsl
*/
static const float3x3 FRX_ACES_INPUT_MATRIX = float3x3(
    float3(0.59719, 0.07600, 0.02840),
    float3(0.35458, 0.90834, 0.13383),
    float3(0.04823, 0.01566, 0.83777)
);

// ODT_SAT => XYZ => D60_2_D65 => sRGB
static const float3x3 FRX_ACES_OUTPUT_MATRIX = float3x3(
    float3(1.60475, -0.10208, -0.00327),
    float3(-0.53108, 1.10813, -0.07276),
    float3(-0.07367, -0.00605, 1.07602)
);

float3 FRX_RRT_AND_ODTF_FIT(float3 v) {
    float3 a = v * (v + 0.0245786) - 0.000090537;
    float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;

    return a / b;
}

public float3 frx_toneMap(float3 color) {
    color = mul(color, FRX_ACES_INPUT_MATRIX);
    color = FRX_RRT_AND_ODTF_FIT(color);

    return mul(color, FRX_ACES_OUTPUT_MATRIX);
}
