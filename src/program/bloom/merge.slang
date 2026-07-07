import aperture;

import lib.sample;

Texture2D inputTexture;
Texture2D bloomUpsampleTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    float2 distance = 1.0 / ap.game.renderSize;

    float4 color = inputTexture.Sample(apt_linearSampler, uv);
    float4 bloomyColor = frx_sampleTent(bloomUpsampleTexture, uv, distance, 0);

    float bloomAmount = 0.1;

    return FragmentOutput(lerp(color, bloomyColor, bloomAmount));
}
