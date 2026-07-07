public module lighting;

import aperture;
import lib.material;
import lib.shadows;
import lib.util;
import lib.sky;
import lib.atmosphere;
import lib.palette;

extern static const float skyLutLightSampleLod = 0.0;

public float3 lighting(
    Texture2D transmittanceLut,
    Texture2D skyLutDay,
    Texture2D skyLutNight,
    float3 sceneSpacePos, 
    Material mat
) {
    float3 lighting = float3(0.0);

    float3 atmosphereSpacePos = getAtmosphereViewingPos() + 1e-6 * sceneSpacePos * minecraftToAtmosphereUnitScale;

    float3 atmosphereAmbientColor = Brightnesses.AMBIENT_SKYLIGHT_BRIGHTNESS * sampleAtmosphere(skyLutDay, skyLutNight, mat.fragNormal, skyLutLightSampleLod);

    float3 ambientLightColor = Brightnesses.CAVE_BRIGHTNESS + atmosphereAmbientColor * mat.skyLight;
    float3 blockLightColor = float3(1.0, 0.5, 0.25) * mat.blockLight;

    lighting += Brightnesses.BLOCKLIGHT_BRIGHTNESS * blockLightColor + ambientLightColor;
    lighting *= mat.ambientOcclusion;

    float sampledShadowFactor = shadowVisibility(sceneSpacePos);
    
    // moon or sun depending on which is higher in the sky
    float3 sunVector = getSunVector();
    float3 lightVector = sunVector * sign(sunVector.y);

    float shadowSunsetFadeFactor = smoothstep(0.01, 0.05, lightVector.y);
    
    float shadowFactor = sampledShadowFactor * shadowSunsetFadeFactor;
    
    float NdotL = saturate(dot(mat.fragNormal, lightVector));
    NdotL *= float(dot(mat.vertexNormal, lightVector) >= 0.0);

    // NdotL = lerp(NdotL, 1.0, mat.sssAmount)

    float3 directLightColor = (
        sunVector.y >= 0.0 ? Brightnesses.SUNLIGHT_BRIGHTNESS * Colors.SUN_COLOR : Brightnesses.MOONLIGHT_BRIGHTNESS * Colors.MOON_COLOR
    ) * getValFromTLUT(transmittanceLut, atmosphereSpacePos, lightVector);

    lighting += directLightColor * shadowFactor * NdotL;

    return lighting;
}