import aperture;

import lib.exposure;
import lib.color;
import lib.palette;

extern static const float minEV100;
extern static const float maxEV100;

RWStructuredBuffer<float> meteredLuminance;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;

    float4 color = inputTexture.Sample(apt_linearSampler, uv);

    float purkinjeAmount = exp(-luminance(color.rgb) * 400.0);

    float3 darkVisionColor = purkinjeShift(color.rgb);
    color.rgb = lerp(color.rgb, darkVisionColor, purkinjeAmount);

    float sceneLuminance = meteredLuminance[0];
    sceneLuminance = clamp(sceneLuminance, 0.008, 0.15);

    // write back to the buffer so other shaders can access this info
    meteredLuminance[0] = sceneLuminance;

    float ev100 = automaticEV100(sceneLuminance, 0.0);
    // ev100 = clamp(ev100, 3.0, 20.0);

    float exposure = getExposure(ev100);

    color.rgb *= exposure;

    return FragmentOutput(color);
}
