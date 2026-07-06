public module lighting;

import aperture;
import lib.material;
import lib.shadows;
import lib.util;

public float3 lighting(float3 sceneSpacePos, Material mat) {
    float3 lighting = float3(0.0);

    float3 ambientBrightness = 0.1 + 0.1 * saturate(dot(mat.fragNormal, getSunVector()));
    float3 ambientLightColor = float3(0.5, 0.8, 0.95) * ambientBrightness;
    float3 blockLightColor = float3(1.0, 0.5, 0.25);

    lighting += blockLightColor * mat.blockLight + ambientLightColor * mat.skyLight;
    lighting *=  mat.ambientOcclusion;

    lighting += shadowVisibility(sceneSpacePos);

    return lighting;
}