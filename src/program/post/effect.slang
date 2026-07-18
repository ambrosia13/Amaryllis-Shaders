import aperture;

import lib.util;
import lib.math;
import lib.space;
import lib.atmosphere;
import lib.sky;
import lib.noise;
import lib.clouds;
import lib.random;
import lib.material;
import lib.lighting;
import lib.face;
import lib.color;
import lib.raytrace;

// for fog
Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewTexture;

TextureCube skyCubemapTexture;

Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

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
    float handDepth = ap.handDepth[coord];
    float opaqueDepth = ap.opaqueDepth[coord];

    float4 normalSample = solidMatNormalsTexture[coord];
    uint4 pbrSample = solidMatPbrTexture[coord];
    float4 lightSample = solidMatLightTexture[coord];

    depth = max(depth, handDepth);

    float3 screenSpacePos = float3(uv, depth);
    float3 screenSpacePosBack = float3(uv, opaqueDepth);

    float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);
    float3 sceneSpacePosBack = screenSpaceToSceneSpace(screenSpacePosBack);

    float distance = length(sceneSpacePos);
    float distanceBack = length(sceneSpacePosBack);
    float3 viewDir = sceneSpacePos / distance;

    Material mat = Material.unpack(normalSample, pbrSample, lightSample);

    if (depth != 0.0) {
        // water effects
        if (mat.isWater()) {
            // first: water fog and absorption
            float waterThickness = distanceBack - distance;
            float transmittance = exp(-waterThickness * 0.1);
            float3 waterScatteringColor = 0.05 * normalizeLuminance(linearizeSrgb(float3(0.1, 0.7, 0.8))) * mat.skyLight;

            color.rgb = lerp(waterScatteringColor, color.rgb, transmittance);

            // now fix up normals and pbr parameters
            mat.roughness = 0.0;
            mat.f0 = 0.04;

            float2 uv = getFaceUv(sceneSpacePos + ap.camera.position, mat.vertexNormal);

            float3x3 tbn = inventTbnMatrix(mat.vertexNormal);

            // float2 gradient = fbmGradient<8>(
            //         N noiseFunction, 
            //         vector<float, DIM> uv,
            //         matrix<float, DIM, DIM> rotationMatrix, 
            //         float lacunarity, 
            //         float t
            // )

            float2 gradient = 0.01 * fbmGradient<1>(
                SimplexNoise2D(),
                uv,
                rotationMatrix(radians(30)),
                2.0,
                ap.timing.timeElapsed
            );

            // mat.fragNormal = normalize(
            //     mul(transpose(tbn), normalize(
            //         cross(float3(-2.0, 0.0, gradient.x), float3(0.0, -2.0, -gradient.y))
            //     ))
            // );

            // color.rg = fract(uv);
        }

        // apply reflections
        if (mat.roughness < 1.0 && mat.f0 > 0.0) {
            float NdotV = dot(mat.fragNormal, -viewDir);

            float3 reflectance = getReflectance(mat.f0, NdotV, mat.roughness);

            float3 reflectedViewDir = reflect(viewDir, mat.fragNormal);
            float3 reflectColor = skyCubemapTexture.Sample(apt_linearSampler, reflectedViewDir).rgb;
            drawSunOnAtmosphere(reflectColor, transmittanceLookupTexture, reflectedViewDir);

            float3 reflectedScreenSpacePos;

            float3 reflectedRayDir = normalize(sceneSpaceToScreenSpace(sceneSpacePos + reflectedViewDir) - screenSpacePos);

            bool hit = raytraceDepth(screenSpacePos, reflectedRayDir, reflectedScreenSpacePos);
            // reflectedScreenSpacePos.xy /= ap.game.renderSize;

            if (hit) {
                reflectColor = inputTexture.Sample(apt_linearSampler, reflectedScreenSpacePos.xy).rgb;
            }

            color.rgb = lerp(color.rgb, reflectColor, reflectance);
        }

        // apply atmospheric aerial perspective fog to the scene
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
