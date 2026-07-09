public module lighting;

import aperture;
import lib.material;
import lib.shadows;
import lib.util;
import lib.sky;
import lib.atmosphere;
import lib.palette;

extern static const float skyLutLightSampleLod = 0.0;

static const uint sssSamples = 4;
static const float sssDepth = 1.0;

public float3 lighting(
    Texture2D transmittanceLut,
    Texture2D skyLutDay,
    Texture2D skyLutNight,
    int2 coord,
    float3 sceneSpacePos, 
    Material mat
) {
    float3 lighting = float3(0.0);

    float distance = length(sceneSpacePos);

    float3 atmosphereSpacePos = getAtmosphereViewingPos() + 1e-6 * sceneSpacePos * minecraftToAtmosphereUnitScale;
    float3 atmosphereAmbientColor = Brightnesses.AMBIENT_SKYLIGHT_BRIGHTNESS * sampleAtmosphere(skyLutDay, skyLutNight, mat.fragNormal, skyLutLightSampleLod);

    float3 ambientLightColor = Brightnesses.CAVE_BRIGHTNESS + atmosphereAmbientColor * mat.skyLight;
    float3 blockLightColor = float3(1.0, 0.5, 0.25) * mat.blockLight;

    lighting += Brightnesses.BLOCKLIGHT_BRIGHTNESS * blockLightColor + ambientLightColor;
    lighting *= mat.ambientOcclusion;

    // moon or sun depending on which is higher in the sky
    float3 sunVector = getSunVector();
    float3 lightVector = sunVector * sign(sunVector.y);
    float shadowSunsetFadeFactor = smoothstep(0.01, 0.05, lightVector.y);

    float sampledShadowFactor = shadowVisibility(coord, sceneSpacePos, distance, mat);

    float sssDistance = 0.0;
    float lightOpticalDepth = 0.0;

    if (mat.sssAmount != 0.0) {
        for (uint i = 0; i < sssSamples; i++) {
            sssDistance += (sssDepth * mat.sssAmount) / sssSamples;
            float sssShadowFactor = shadowVisibility(coord, sceneSpacePos + lightVector * sssDistance, distance, mat);

            lightOpticalDepth += sssShadowFactor / sssSamples;
        }
    }   

    float sssTransmittance = exp(-lightOpticalDepth);

    float shadowFactor = sampledShadowFactor * shadowSunsetFadeFactor;
    
    float NdotL = saturate(dot(mat.fragNormal, lightVector));
    NdotL *= float(dot(mat.vertexNormal, lightVector) >= 0.0);

    shadowFactor *= NdotL;
    shadowFactor = lerp(1.0, shadowFactor, sssTransmittance);

    float3 directLightColor = (
        sunVector.y >= 0.0 ? Brightnesses.SUNLIGHT_BRIGHTNESS * Colors.SUN_COLOR : Brightnesses.MOONLIGHT_BRIGHTNESS * Colors.MOON_COLOR
    ) * getValFromTLUT(transmittanceLut, atmosphereSpacePos, lightVector);

    lighting += directLightColor * shadowFactor;

    return lighting;
}