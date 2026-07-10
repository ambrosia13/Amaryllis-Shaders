import aperture;

import lib.util;
import lib.math;
import lib.space;
import lib.atmosphere;
import lib.sky;
import lib.noise;
import lib.clouds;
import lib.random;

// for fog
Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewTexture;

// Texture2D cellular2DTexture;

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
            8, // based on eyeballing, we can go this low without a noticeable drop in quality at all times of day
            fogTransmittance
        );

        // color.rgb = fogScattering;
        color.rgb = lerp(color.rgb, color.rgb * fogTransmittance + fogScattering, ap.camera.brightness.y);
    }

    // TextureNoise2D texNoise = TextureNoise2D(cellular2DTexture);
    // // color *= float(smoothstep(0.5, 0.7, fbm<8>(texNoise, uv * 3.0, rotationMatrix(radians(30)), 2.0, ap.timing.timeElapsed * 0.01) * 0.5 + 0.5));
    // color *= smoothstep(0.5, 0.7, texNoise.getValue(fract(uv * 2.0), 0.0));

    // Random<Ign> random = Random<Ign>(Ign(int2(pos), ap.timing.frameCounter));

    // float2 plane = viewDir.xz / viewDir.y;

    // if (viewDir.y > 0.001) {
    //     float2 gradient;
    //     float2 bleh = CumulusClouds().getTransmittanceAndScattering(random, viewDir);
    //     drawCloudsOnAtmosphere<CumulusClouds>(color.rgb, transmittanceLookupTexture, skyViewTexture, viewDir, bleh);
    // }

    return FragmentOutput(color);
}
