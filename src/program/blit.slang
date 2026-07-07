import aperture;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;

    return FragmentOutput(inputTexture.Sample(apt_linearSampler, uv));
}
