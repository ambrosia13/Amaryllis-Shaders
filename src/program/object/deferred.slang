import aperture;

import lib.material;
import lib.lighting;
import lib.space;
import lib.atmosphere;
import lib.sky;
import lib.util;
import lib.color;
import lib.raytrace;

RWTexture2D targetTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;
Texture2D skyViewTexture;
TextureCube skyCubemapTexture;

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void main(uint3 globalInvocationId: SV_DispatchThreadID) {
    if (any(globalInvocationId.xy >= ap.game.renderSize)) {
        return;
    }

    float2 uv = float2(globalInvocationId.xy) / ap.game.renderSize;

    // albedo is stored in the input texture at this point
    float3 color = targetTexture[globalInvocationId.xy].rgb;

    float4 matNormalsSample = solidMatNormalsTexture[globalInvocationId.xy];
    uint4 matPbrSample = solidMatPbrTexture[globalInvocationId.xy];
    float4 matLightSample = solidMatLightTexture[globalInvocationId.xy];

    Material mat = Material.unpack(matNormalsSample, matPbrSample, matLightSample);

    float depth = ap.opaqueDepth[globalInvocationId.xy];

    float3 screenSpacePos = float3(uv, depth);
    float3 sceneSpacePos = screenSpaceToSceneSpace(screenSpacePos);

    float3 viewDir = normalize(sceneSpacePos);

    // VoxelHit hit;
    // if (raytraceVoxelMap(ap.camera.position, viewDir, 16, hit)) {
    //     color = float3(1);
    //     sceneSpacePos = hit.pos;
    //     mat.fragNormal = hit.normal;
    //     mat.vertexNormal = hit.normal;
    //     mat.ambientOcclusion = 1.0;
    //     mat.sssAmount = 0.0;
    // }

    if (depth != 0.0) {
        // convert to working color space before lighting
        color = linearizeSrgb(color);
        color = mul(sRGBtoAP1, color);

        float shadowFactor = 1.0;



        color *= lighting(
            transmittanceLookupTexture,
            skyCubemapTexture,
            globalInvocationId.xy,
            sceneSpacePos, 
            mat,
            color.rgb,
            shadowFactor
        );
    } else {
        // sky!
        // color = skyCubemapTexture.SampleLevel(apt_linearSampler, viewDir, 4).rgb;

        color = getValFromSkyLUT(skyViewTexture, viewDir, getSunVector());
        drawSunOnAtmosphere(color, transmittanceLookupTexture, viewDir);
    }

    targetTexture.Store(globalInvocationId.xy, float4(color, 1.0));
}
