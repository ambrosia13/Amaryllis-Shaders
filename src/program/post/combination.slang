import aperture;

import lib.space;
import lib.random;

Texture2D outputTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    float3 color = outputTexture[coord].rgb;

    color = tanh(color);

    color = pow(color, float3(1.0 / 2.2));


    return saturate(float4(color, 1.0));

    // uint randomSeed = coord.x + coord.y * ap.game.renderSize.x;
    // Random random = Random(0);

    // float depth = ap.depth[coord];
    // float3 screenSpacePos = float3(uv, depth);
    // float3 viewSpacePos = screenSpaceToViewSpace(screenSpacePos);

    // float3 viewSpaceDir = normalize(viewSpacePos);

    // float centerDepth = ap.depth.sampleLinear(float2(0.5));
    // float focusDistance = -screenSpaceToViewSpace(float3(float2(0.5), centerDepth)).z;

    // float3 targetViewSpacePos = viewSpaceDir * (focusDistance / viewSpacePos.z); // the intersection between the pinhole ray and the focal plane
    
    // float apertureRadius = 0.025;

    // float3 rayPos = float3(float2(sin(ap.timing.timeElapsed), cos(ap.timing.timeElapsed)) * apertureRadius, 0.0);
    // float3 rayScreenPos = float3(screenSpacePos.xy, 0.0);
    // float3 rayDir = normalize(targetViewSpacePos - rayPos);
    
    // const uint steps = 300;
    // bool foundIntersection = false;
    
    // float rayStep = 300.0 / steps;

    // for (uint i = 0; i < steps; i++) {
    //     rayPos += rayDir * rayStep;
    //     rayScreenPos = viewSpaceToScreenSpace(rayPos);

    //     if (any(clamp(rayScreenPos.xy, float2(0.0), float2(1.0)) != rayScreenPos.xy)) break;

    //     float sampleDepth = ap.depth.sampleNearest(rayScreenPos.xy);
    //     float3 samplePos = screenSpaceToViewSpace(float3(rayScreenPos.xy, sampleDepth));
        
    //     if (samplePos.z < rayPos.z) {
    //         foundIntersection = true;
    //         break;
    //     }
    // }

    // // return float4(rayScreenPos.xy, 0, 1);
    // return saturate(outputTexture.Sample(apt_linearSampler, select(foundIntersection, rayScreenPos.xy, screenSpacePos.xy)));
}
