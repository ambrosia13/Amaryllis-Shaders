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
import lib.shadows;

// for fog
Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewTexture;

TextureCube skyCubemapTexture;

Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

Texture2D inputTexture;

Texture2D preOverlayHistory;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    Random<Ign> random = Random<Ign>(Ign(int2(coord), ap.timing.frameCounter));

    float3 color = inputTexture.Sample(apt_linearSampler, uv).rgb;

    float depth = ap.depth[coord];
    float opaqueDepth = ap.opaqueDepth[coord];

    float4 normalSample = solidMatNormalsTexture[coord];
    uint4 pbrSample = solidMatPbrTexture[coord];
    float4 lightSample = solidMatLightTexture[coord];

    float3 screenSpacePos = float3(uv, depth);
    float3 screenSpacePosBack = float3(uv, opaqueDepth);

    float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);
    float3 sceneSpacePosBack = screenSpaceToSceneSpace(screenSpacePosBack);

    float distance = length(sceneSpacePos);
    float distanceBack = length(sceneSpacePosBack);
    float3 viewDir = sceneSpacePos / distance;

    Material mat = Material.unpack(normalSample, pbrSample, lightSample);

    if (depth != 0.0) {
        float3 atmosphereTopColor = skyCubemapTexture.SampleLevel(apt_linearSampler, float3(0, 1, 0), skyCubemapMips).rgb;

        // water effects
        if (mat.isWater() || ap.camera.fluid == 1) {
            // first: water fog and absorption
            float waterThickness = ap.camera.fluid == 0 ? distanceBack - distance : distance;

            float3 waterColor = normalizeLuminance(linearizeSrgb(float3(0.1, 0.7, 0.8)));

            float waterDensity = 0.25;
            float opticalDepth = waterThickness;
            float lightOpticalDepth = 0.0;
            uint waterScatteringSteps = 8;
            uint waterScatteringSecondarySteps = 8;

            float3 lightVector = getLightVector();

            float VdotL = (dot(viewDir, lightVector));
            float volumetricLightFactor = 0.0;

            for (uint i = 0; i < waterScatteringSteps; i++) {
                float3 rayPos = lerp(ap.camera.fluid == 1 ? float3(0) : sceneSpacePos, sceneSpacePosBack, (i + random.getFloat()) / float(waterScatteringSteps));

                float4 shadowViewSpacePos = setupShadowViewSpacePos(rayPos, 0, float3(0));
                float3 shadowScreenSpacePos;
                uint cascade = selectShadowCascade(shadowViewSpacePos, shadowScreenSpacePos);

                bool outOfBounds;
                volumetricLightFactor += (1.0 / 64.0) 
                    * (shadowVisibility<false, Ign>(random, cascade, shadowScreenSpacePos, 0.0, 1, outOfBounds)) / waterScatteringSteps 
                    * (ap.camera.fluid == 0 ? length(sceneSpacePosBack - sceneSpacePos) : length(sceneSpacePos));
            }

            float3 waterScattering = 0.1 * waterColor * luminance(atmosphereTopColor) * (1.0 + 16.0 * volumetricLightFactor * getMiePhase(VdotL, 0.5));
            float transmittance = exp(-opticalDepth * waterDensity);            
            
            color.rgb = lerp(waterScattering, color.rgb, transmittance);

        }

        if (mat.isWater()) {
            // now fix up normals and pbr parameters
            mat.roughness = 0.0;
            mat.f0 = 0.04;

            float2 uv = getFaceUv(sceneSpacePos + ap.camera.position, mat.vertexNormal);

            float3x3 tbn = inventTbnMatrix(mat.vertexNormal);

            float2 gradient = 0.01 * fbmGradient(
                SimplexNoise2D(),
                uv,
                rotationMatrix(radians(30)),
                4,
                2.0,
                ap.timing.timeElapsed
            );

            mat.fragNormal = normalize(
                mul(transpose(tbn), normalize(
                    cross(float3(-2.0, 0.0, gradient.x), float3(0.0, -2.0, -gradient.y))
                ))
            );

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

            if (hit) {
                reflectColor = preOverlayHistory.Sample(apt_linearSampler, reflectedScreenSpacePos.xy).rgb;
            }

            color.rgb = lerp(color.rgb, reflectColor, reflectance);
        }

        if (ap.camera.fluid == 0) {
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

            color.rgb = lerp(color.rgb, color.rgb * fogTransmittance + fogScattering, ap.camera.brightness.y);
        }
    }

    return FragmentOutput(float4(color, 1));
}
