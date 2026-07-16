import aperture;

import lib.material;
import lib.lighting;
import lib.space;
import lib.atmosphere;
import lib.sky;
import lib.util;

Texture2D solidAlbedoTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewTexture;
TextureCube skyCubemapTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
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
            skyCubemapTexture,
            coord,
            sceneSpacePos, 
            mat
        );
    } else {
        // sky!
        color = skyCubemapTexture.SampleLevel(apt_linearSampler, viewDir, 6).rgb;

        // color = getValFromSkyLUT(skyViewTexture, viewDir, getSunVector());
        drawSunOnAtmosphere(color, transmittanceLookupTexture, viewDir);
    }


    FragmentOutput output;

    output.color = float4(color, 1.0);

    return output;
}
