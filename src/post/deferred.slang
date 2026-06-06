import aperture;

import lib.material;

Texture2D solidAlbedoTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float3 albedo = solidAlbedoTexture[uint2(pos)].rgb;

    float4 matNormalsSample = solidMatNormalsTexture[uint2(pos)];
    uint4 matPbrSample = solidMatPbrTexture[uint2(pos)];
    float4 matLightSample = solidMatLightTexture[uint2(pos)];

    Material mat = Material.unpack(matNormalsSample, matPbrSample, matLightSample);

    FragmentOutput output;

    output.color = float4(albedo, 1.0);

    return output;
}
