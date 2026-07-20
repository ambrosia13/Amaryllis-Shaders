import aperture;

import lib.math;

extern static const uint hiDepthMaxLevels;

Texture2D<float> hiDepthTexture;

float getCellSize(uint lod) {
    return 1 << lod;
}

void getTraversalDists(
    float3 pos, 
    float3 dir,
    uint level,
    out float2 stepSizes,
    out float2 nextDist,
) {
    float2 cellSpacePos = pos.xy / getCellSize(level);
    float2 cellSpaceDir = dir.xy / getCellSize(level);

    float2 stepDir = sign(cellSpaceDir); // unitless
    
    stepSizes = 1.0 / abs(cellSpaceDir); // in units of cells
    nextDist = (stepDir * 0.5 + 0.5 - fract(cellSpacePos)) / cellSpaceDir; // in units of cells
}

public bool raytraceDepth(
    // is (screenCoord, depth)
    float3 screenSpacePos,
    float3 rayDir,
    out float3 intersection,
) {
    uint currentLevel = 3;

    float3 windowSpacePos = screenSpacePos * float3(ap.game.renderSize, 1.0);
    float3 windowSpaceDir = rayDir * float3(ap.game.renderSize, 1.0);

    float2 stepSizes;
    float2 nextDist;

    getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepSizes, nextDist);

    for (uint i = 0; i < 80; i++) {
        float closestDist = min(nextDist.x, nextDist.y); // in units of cells
        float windowSpaceDist = closestDist * getCellSize(currentLevel); // in unit of pixels

        windowSpacePos += windowSpaceDist * windowSpaceDir;

        float2 stepAxis = float2(nextDist <= float2(closestDist));

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;

        // move to center of texel before sampling
        float3 currentScreenSpacePos = (windowSpacePos + float3(0.5, 0.5, 0.0)) / float3(ap.game.renderSize, 1.0);
        
        if (any(currentScreenSpacePos < float3(0)) || any(currentScreenSpacePos >= float3(1))) {
            break;
        }

        float depthSample = hiDepthTexture.SampleLevel(apt_nearestSampler, currentScreenSpacePos.xy, currentLevel);

        if (depthSample > currentScreenSpacePos.z) {
            if (currentLevel == 0) {
                intersection = currentScreenSpacePos;
                return true;
            }

            // we have to go back a level, so go back to previous position
            windowSpacePos -= windowSpaceDist * windowSpaceDir;

            // ...and then advance to the itnersection with the sampled depth plane
            float distToSampledDepth = (depthSample - windowSpacePos.z) / windowSpaceDir.z;
            windowSpacePos += distToSampledDepth * windowSpaceDir;

            currentLevel -= 1;

            // recalculate distances and sizes based on level
            getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepSizes, nextDist);
        } else {
            // go up a level (?)
            // currentLevel += 1;
            // getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepSizes, nextDist);
        }
    }

    return false;
}
