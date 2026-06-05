import aperture;

Texture2D mainTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    return mainTexture[uint2(pos)];
}
