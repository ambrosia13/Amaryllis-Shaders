import aperture;

extern static const int lod;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    uint2 coord = uint2(pos);

    return FragmentOutput(0.25 * (
        inputTexture.Load(uint3(coord + uint2(0, 0), max(0, lod - 1))) +
        inputTexture.Load(uint3(coord + uint2(1, 0), max(0, lod - 1))) +
        inputTexture.Load(uint3(coord + uint2(0, 1), max(0, lod - 1))) +
        inputTexture.Load(uint3(coord + uint2(1, 1), max(0, lod - 1)))
    ));
}
