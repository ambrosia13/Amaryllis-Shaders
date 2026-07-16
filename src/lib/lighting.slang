public module lighting;

import aperture;

import lib.material;
import lib.shadows;
import lib.util;
import lib.atmosphere;
import lib.palette;
import lib.random;
import lib.math;

extern static const uint skyCubemapMips = 0;

static const uint sssSamples = 4;
static const float sssDepth = 1.0;

public float3 lighting(
    Texture2D transmittanceLut,
    TextureCube skyCubemap,
    int2 coord,
    float3 sceneSpacePos, 
    Material mat
) {
    float3 lighting = float3(0.0);

    Random<Ign> random = Random<Ign>(Ign(coord, ap.timing.frameCounter));

    float distance = length(sceneSpacePos);

    // moon or sun depending on which is higher in the sky
    float3 sunVector = getSunVector();
    float3 lightVector = sunVector * sign(sunVector.y);
    float shadowSunsetFadeFactor = smoothstep(0.01, 0.05, lightVector.y);

    float3 atmosphereSpacePos = getAtmosphereViewingPos() + 1e-6 * sceneSpacePos * minecraftToAtmosphereUnitScale;
    float3 atmosphereAmbientColor = Brightnesses.AMBIENT_SKYLIGHT_BRIGHTNESS * skyCubemap.SampleLevel(apt_linearSampler, mat.fragNormal, skyCubemapMips).rgb;
    float3 atmosphereTopColor = Brightnesses.AMBIENT_SKYLIGHT_BRIGHTNESS * skyCubemap.SampleLevel(apt_linearSampler, float3(0, 1, 0), skyCubemapMips).rgb;

    // materials with sss should have more uniform looking lighting across faces
    atmosphereAmbientColor = lerp(atmosphereAmbientColor, atmosphereTopColor, mat.sssAmount);

    float3 ambientLightColor = Brightnesses.CAVE_BRIGHTNESS + atmosphereAmbientColor * mat.skyLight;
    float3 blockLightColor = float3(1.0, 0.5, 0.25) * mat.blockLight;

    lighting += Brightnesses.BLOCKLIGHT_BRIGHTNESS * blockLightColor + ambientLightColor;
    lighting *= mat.ambientOcclusion;

    float basePenumbraSize = 1.0;
    float4 shadowViewSpacePos = setupShadowViewSpacePos(sceneSpacePos, distance, mat);
    
    float sampledShadowFactor = shadowVisibility<true, Ign>(random, shadowViewSpacePos, basePenumbraSize, lightVector, mat);

    float sssDistance = 0.0;
    float lightOpticalDepth = 0.0;

    if (mat.sssAmount != 0.0) {
        for (uint i = 0; i < sssSamples; i++) {
            sssDistance += (sssDepth * mat.sssAmount) / sssSamples;

            shadowViewSpacePos = setupShadowViewSpacePos(sceneSpacePos + lightVector * sssDistance, distance, mat);
            float sssShadowFactor = shadowVisibility<false, Ign>(random, shadowViewSpacePos, basePenumbraSize + float(i) * 4.0, lightVector, mat);

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

// public float3 translucentVolumeLighting(

// )

public float specularDistribution(float NdotH, float roughness) {
    float a = NdotH * roughness;
    float k = roughness / (1.0 - pow2(NdotH) + pow2(a));
    return k * k * (1.0 / PI);
}

// Schlick fresnel approximation
public float3 getReflectance(float3 f0, float NdotV, float roughness) {
    float3 r = f0 + (1.0 - f0) * pow(1.0 - NdotV, 5.0);

    return lerp(r, min(r, float3(0.1)), roughness);
}
