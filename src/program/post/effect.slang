import aperture;

import lib.space;
import lib.atmosphere;
import lib.sky;

// for fog
Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    float4 color = inputTexture.Sample(apt_linearSampler, uv);

    float depth = ap.depth[coord];
    depth = max(depth, ap.handDepth[coord]);

    float3 screenSpacePos = float3(uv, depth);    

    float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);
    float distance = length(sceneSpacePos);
    float3 viewDir = sceneSpacePos / distance;

    if (depth != 0.0) {
        float3 fogTransmittance;
        float3 fogScattering = raymarchAtmosphere(
            transmittanceLookupTexture,
            multiscatteringLookupTexture,
            getAtmosphereViewingPos(),
            viewDir,
            0.0,
            distance * 1e-6 * minecraftToAtmosphereUnitScale,
            fogTransmittance
        );

        color.rgb = lerp(color.rgb, color.rgb * fogTransmittance + fogScattering, ap.camera.brightness.y);
    }

    return FragmentOutput(color);
}
