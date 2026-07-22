import aperture;

import lib.math;

extern static const uint hiDepthLevelCount;

Texture2D<float> hiDepthTexture;

float getCellSize(uint lod) {
    return 1 << lod;
}

void getTraversalDists(
    float3 pos, 
    float3 dir,
    uint level,
    out float2 stepDir,
    out float2 stepSizes,
    out float2 nextDist,
    out int2 cell
) {
    float2 cellSpacePos = pos.xy / getCellSize(level);
    float2 cellSpaceDir = dir.xy / getCellSize(level);

    stepDir = sign(cellSpaceDir); // unitless
    
    stepSizes = 1.0 / abs(cellSpaceDir); // in units of cells
    nextDist = (stepDir * 0.5 + 0.5 - fract(cellSpacePos)) / cellSpaceDir; // in units of cells

    cell = int2(floor(cellSpacePos));
}

public bool raytraceDepth(
    // is (screenCoord, depth)
    float3 screenSpacePos,
    float3 rayDir,
    out float3 intersection,
) {
    uint maxLevel = hiDepthLevelCount - 1;
    uint currentLevel = maxLevel;

    float3 windowSpacePos = screenSpacePos * float3(ap.game.renderSize, 1.0);
    float3 windowSpaceDir = rayDir * float3(ap.game.renderSize, 1.0);

    float2 stepDir, stepSizes, nextDist;
    int2 cell;

    getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);

    for (uint i = 0; i < 80; i++) {
        // if direction is axis aligned (ie one axis is zero), discourage stepping along that axis because step size there is inf or nan
        nextDist = select(abs(windowSpaceDir.xy) < 0.00001, float2(float.maxValue), nextDist);
        
        float closestDist = min(nextDist.x, nextDist.y); // in units of cells
        float windowSpaceDist = closestDist * getCellSize(currentLevel); // in unit of pixels

        windowSpacePos += windowSpaceDist * windowSpaceDir;

        float2 stepAxis = float2(nextDist <= float2(closestDist));

        int2 previousCell = cell;
        cell += int2(stepAxis * stepDir);

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;

        int2 cellCount = ap.game.renderSize >> currentLevel;
        if (any(cell < int2(0)) || any(cell >= cellCount)) {
            break;
        }

        float depthSample = hiDepthTexture.Load(int3(cell, currentLevel));

        if (depthSample > 0.0 && depthSample > windowSpacePos.z) {
            if (currentLevel == 0) {
                intersection = windowSpacePos / float3(ap.game.renderSize, 1.0);
                return true;
            }

            // we have to go back a level, so go back to previous position
            windowSpacePos -= windowSpaceDist * windowSpaceDir;

            // ...and then advance to the itnersection with the sampled depth plane
            // aka the farthest we can go from the currently known information (sampled depth)
            float distToSampledDepth = max(0.0, (depthSample - windowSpacePos.z) / windowSpaceDir.z);
            windowSpacePos += distToSampledDepth * windowSpaceDir;

            currentLevel -= 1;

            // recalculate distances and sizes based on level
            getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);
        } else {
            bool parentCellAdvanced = any((previousCell >> 1) != (cell >> 1));

            // go up a level if outside the confines of the parent cell we descended from
            if (currentLevel < maxLevel && parentCellAdvanced) {
                currentLevel += 1;
                getTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);
            }
        }
    }

    return false;
}
