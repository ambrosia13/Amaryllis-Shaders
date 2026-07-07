import aperture;

extern static const int lod;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    int2 coord = int2(pos);

    return FragmentOutput(0.25 * (
        inputTexture.Load(int3(coord + int2(0, 0), max(0, lod - 1))) +
        inputTexture.Load(int3(coord + int2(1, 0), max(0, lod - 1))) +
        inputTexture.Load(int3(coord + int2(0, 1), max(0, lod - 1))) +
        inputTexture.Load(int3(coord + int2(1, 1), max(0, lod - 1)))
    ));
}
