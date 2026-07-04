import aperture;

import lib.material;
import lib.lighting;
import lib.space;

Texture2D solidAlbedoTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float3 color = solidAlbedoTexture[uint2(pos)].rgb;

    float4 matNormalsSample = solidMatNormalsTexture[uint2(pos)];
    uint4 matPbrSample = solidMatPbrTexture[uint2(pos)];
    float4 matLightSample = solidMatLightTexture[uint2(pos)];

    Material mat = Material.unpack(matNormalsSample, matPbrSample, matLightSample);

    float depth = ap.opaqueDepth[uint2(pos)];
    float handDepth = ap.handDepth[uint2(pos)];

    // since the deferred target includes the hand, merge with that before proceeding
    depth = max(depth, handDepth);

    if (depth != 0.0) {
        float3 screenSpacePos = float3(pos / ap.game.renderSize, depth);
        float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);

        float3 viewDir = normalize(sceneSpacePos);
        // color = float3(viewDir);
        // color = sceneSpacePos / 100.0;
        // color = float3(1.0, 0.0, 0.0);
        color *= lighting(sceneSpacePos, mat);
    }


    FragmentOutput output;

    output.color = float4(color, 1.0);

    return output;
}
