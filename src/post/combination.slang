import aperture;

#define def_outputTexture mainTexture_a

Texture2D def_outputTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    return saturate(def_outputTexture[uint2(pos)]);
}
