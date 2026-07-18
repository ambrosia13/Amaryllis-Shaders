import aperture;

import lib.math;

extern static const uint hiDepthMaxLevels;

Texture2D<float> hiDepthTexture;

float getCellSize(uint lod) {
    return 1 << lod;
}

float2 getCellPos(float2 screenCoord, uint lod) {
    return float2(uint2(screenCoord) << lod);
}

float2 getScreenCoord(float2 cellPos, uint lod) {
    return float2(uint2(cellPos) >> lod);
}

// float2 getAdvanceDist(float2 screenCoord, float2 rayDirXY, inout uint nextDist, uint lod) {
//     float2 cellPos = getCellPos(screenCoord, lod);

//     float2 stepSizes = 1.0 / rayDirXY;
//     float2 stepDir = sign(rayDirXY);

//     float2 nextDist = (stepDir * 0.5 + 0.5 - fract(cellPos)) ;
// }

public bool raytraceDepth(
    // is (screenCoord, depth)
    float3 screenSpacePos,
    float3 rayDir,
    out float3 intersection,
) {
    // for (uint i = 0; i < 80; i++) {
    //     screenSpacePos += rayDir / 80;

    //     if (any(screenSpacePos < float3(0.0)) || any(screenSpacePos >= float3(1.0))) {
    //         return false;
    //     }

    //     float depth = hiDepthTexture.SampleLevel(apt_linearSampler, screenSpacePos.xy, 0);

    //     if (depth > screenSpacePos.z) {
    //         intersection = screenSpacePos;
    //         return true;
    //     }
    // }

    uint currentLevel = hiDepthMaxLevels - 1;

    float3 windowSpacePos = screenSpacePos * float3(ap.game.renderSize, 1.0);
    float3 windowSpaceDir = rayDir * float3(ap.game.renderSize, 1.0);

    float2 cellSpacePos = windowSpacePos.xy / getCellSize(currentLevel);
    float2 cellSpaceDir = windowSpaceDir.xy / getCellSize(currentLevel);

    float2 stepSizes = 1.0 / abs(cellSpaceDir); // in units of cells
    float2 stepDir = sign(cellSpaceDir); // unitless
    float2 nextDist = (stepDir * 0.5 + 0.5 - fract(cellSpacePos)) / cellSpaceDir; // in units of cells

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
            currentLevel -= 1;

            // recalculate distances and sizes based on level
            cellSpacePos = windowSpacePos.xy / getCellSize(currentLevel);
            cellSpaceDir = windowSpaceDir.xy / getCellSize(currentLevel);

            stepSizes = 1.0 / abs(cellSpaceDir); // in units of cells
            stepDir = sign(cellSpaceDir); // unitless
            nextDist = (stepDir * 0.5 + 0.5 - fract(cellSpacePos)) / cellSpaceDir; // in units of cells
        }
    }

    // uint currentLevel = 0;

    // float2 rayDirXY = (windowSpaceDir.xy);

    // float2 stepSizes = 1.0 / abs(rayDirXY);
    // float2 stepDir = sign(rayDirXY);


    // const uint maxSteps = 80;

    // for (uint i = 0; i < maxSteps; i++) {
    //     float2 cellSpacePos = windowSpacePos.xy / getCellSize(currentLevel);
    //     float2 posInCell = fract(cellSpacePos);

    //     float2 nextDist = (stepDir * 0.5 + 0.5 - posInCell);

    //     float closestDist = min(nextDist.x, nextDist.y);

    //     // multiply by cell size since we divided earlier to get "cell-space" position
    //     windowSpacePos += windowSpaceDir * closestDist * getCellSize(currentLevel);

    //     if (any(windowSpacePos.xy < float2(0.0)) || any(windowSpacePos.xy > ap.game.renderSize)) {
    //         return false;
    //     }

    //     float sampledDepth = hiDepthTexture.SampleLevel(apt_nearestSampler, windowSpacePos.xy / ap.game.renderSize, currentLevel);

    //     if (sampledDepth > windowSpacePos.z) { // found intersection
    //         intersection = float3(windowSpacePos.xy / ap.game.renderSize, sampledDepth);
    //         return true;
    //     }

    //     // float2 stepAxis = float2(nextDist <= float2(closestDist));

    //     // nextDist -= closestDist;
    //     // nextDist += stepSizes + stepAxis;
    // }

    return false;
}
