import aperture;

import lib.material;
import lib.lighting;
import lib.space;
import lib.sky;
import lib.util;

Texture2D solidAlbedoTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewDayTexture;
Texture2D skyViewNightTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    int2 coord = int2(pos);

    float3 color = solidAlbedoTexture[coord].rgb;

    float4 matNormalsSample = solidMatNormalsTexture[coord];
    uint4 matPbrSample = solidMatPbrTexture[coord];
    float4 matLightSample = solidMatLightTexture[coord];

    Material mat = Material.unpack(matNormalsSample, matPbrSample, matLightSample);

    float depth = ap.opaqueDepth[coord];
    float handDepth = ap.handDepth[coord];

    // since the deferred target includes the hand, merge with that before proceeding
    depth = max(depth, handDepth);

    float3 screenSpacePos = float3(pos / ap.game.renderSize, depth);
    float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);

    float3 viewDir = normalize(sceneSpacePos);

    if (depth != 0.0) {
        color *= lighting(
            transmittanceLookupTexture,
            skyViewDayTexture,
            skyViewNightTexture,
            coord,
            sceneSpacePos, 
            mat
        );
    } else {
        // sky!
        color = sampleAtmosphere(skyViewDayTexture, skyViewNightTexture, viewDir, 0.0);
        drawSunOnAtmosphere(color, transmittanceLookupTexture, viewDir);
    }


    FragmentOutput output;

    output.color = float4(color, 1.0);

    return output;
}
