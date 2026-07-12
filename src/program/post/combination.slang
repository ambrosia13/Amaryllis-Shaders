import aperture;

import lib.space;
import lib.random;
import lib.exposure;
import lib.color;
import lib.tonemap;

extern static const bool showHistogram = true;
extern static const int histogramBins = 256;
extern static const float minLuminance = 0.000001;
extern static const float maxLuminance = 2.0;
StructuredBuffer<uint> histogram;
StructuredBuffer<float> meteredLuminance;

Texture2D outputTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    float3 color = outputTexture.SampleLevel(apt_linearSampler, uv, 3.0).rgb;

    // tonemap and gamma correct
    color = acesFitTonemap(color);

    // deubg view for histogram
    if (showHistogram) {
        float debugViewAlpha = 0.7;

        float sceneLuminance = meteredLuminance[0];
        uint exposedBin = getBinIndex(sceneLuminance, minLuminance, maxLuminance, histogramBins);

        float2 histogramBegin = float2(10.0);
        float2 histogramEnd = histogramBegin + float2(histogramBins, 128.0);

        float scale = 0.4;
        float2 scaledPos = pos * scale;
        
        if (all(scaledPos > histogramBegin) && all(scaledPos < histogramEnd)) {
            float normalizedX = (scaledPos.x - histogramBegin.x) / (histogramEnd.x - histogramBegin.x);
            uint binIndex = uint(floor(normalizedX * histogramBins));
            binIndex = min(binIndex, histogramBins - 1);

            float count = float(histogram[binIndex]);
            float countScale = 1024.0;

            float height = clamp(count / countScale, 0.0, histogramEnd.y - histogramBegin.y) + histogramBegin.y;

            float3 histogramColor = scaledPos.y < height ? 
                (binIndex == exposedBin ? float3(1.0, 0.0, 0.0) : float3(1.0)) : 
                float3(0.0);
            
            color = lerp(color, histogramColor, debugViewAlpha);
        }
    }


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
