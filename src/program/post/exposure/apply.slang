import aperture;

import lib.exposure;
import lib.palette;

extern static const float minEV100;
extern static const float maxEV100;

StructuredBuffer<float> meteredLuminance;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;

    float4 color = inputTexture.Sample(apt_linearSampler, uv);

    float sceneLuminance = meteredLuminance[0];
    sceneLuminance = clamp(sceneLuminance, Brightnesses.NIGHT_SKY_BRIGHTNESS * 0.1, 1.0);

    float ev100 = automaticEV100(sceneLuminance, 0.0);
    // ev100 = clamp(ev100, 3.0, 20.0);

    float exposure = getExposure(ev100);

    color.rgb *= exposure;

    return FragmentOutput(color);
}
