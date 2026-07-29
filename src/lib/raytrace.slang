import aperture;

import lib.math;

extern static const uint hiDepthLevelCount;

Texture2D<float> hiDepthTexture;
RWTexture2D<uint> hiZDebugTexture[];

float getHiZCellSize(uint lod) {
    return 1 << lod;
}

void getHiZTraversalDists(
    float3 pos, 
    float3 dir,
    uint level,
    out float2 stepDir,
    out float2 stepSizes,
    out float2 nextDist,
    out int2 cell
) {
    float2 cellSpacePos = pos.xy / getHiZCellSize(level);
    float2 cellSpaceDir = dir.xy / getHiZCellSize(level);

    stepDir = sign(cellSpaceDir); // unitless
    
    stepSizes = 1.0 / abs(cellSpaceDir); // in units of cells
    nextDist = (stepDir * 0.5 + 0.5 - fract(cellSpacePos)) / cellSpaceDir; // in units of cells

    cell = int2(floor(cellSpacePos));
}

public bool raytraceDepth(
    float3 screenSpacePos,
    float3 rayDir,
    out float3 intersection,
    bool writeDebug,
) {
    uint maxLevel = 7;
    uint currentLevel = maxLevel;

    float3 windowSpacePos = screenSpacePos * float3(ap.game.renderSize, 1.0);
    float3 windowSpaceDir = rayDir * float3(ap.game.renderSize, 1.0);

    float2 stepDir, stepSizes, nextDist;
    int2 cell;

    // mark the starting positions of each cell
    for (uint i = 0; i <= currentLevel; i++) {
        getHiZTraversalDists(windowSpacePos, windowSpaceDir, i, stepDir, stepSizes, nextDist, cell);
        if (writeDebug) hiZDebugTexture[i].Store(cell, 2);
    }
    
    getHiZTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);

    if(writeDebug) {
        hiZDebugTexture[currentLevel].Store(cell, 1);
        printf("starting from level %u, with cell position [%d, %d] and screen coords [%.2f, %.2f]\n", currentLevel, cell.x, cell.y, windowSpacePos.x, windowSpacePos.y);
    }

    for (uint i = 0; i < 80; i++) {
        // if direction is axis aligned (ie one axis is zero), discourage stepping along that axis because step size there is inf or nan
        nextDist = select(abs(windowSpaceDir.xy) < 0.00001, float2(float.maxValue), nextDist);
        
        float closestDist = min(nextDist.x, nextDist.y); // in units of cells
        float windowSpaceDist = closestDist;// * getHiZCellSize(currentLevel); // in unit of pixels // apparently not? avoiding this multiply makes numbers that make sense
        // windowSpaceDist = max(windowSpaceDist, 0.0) * 1.01;

        float3 previousWindowSpacePos = windowSpacePos;
        windowSpacePos += windowSpaceDist * windowSpaceDir;
 
        int2 stepAxis = int2(nextDist <= float2(closestDist));
        
        int2 previousCell = cell;
        cell += stepAxis * int2(stepDir);
        
        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;

        int2 cellCount = ap.game.renderSize >> currentLevel;
        if (any(cell < int2(0)) || any(cell >= cellCount)) {
            // we can only be sure we are OOB if at lod 0, so step down a level until that is the case
            if (currentLevel > 0) {
                windowSpacePos = previousWindowSpacePos;
                currentLevel -= 1;

                // recalculate distances and sizes based on level
                getHiZTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);
                continue;
            }

            if (writeDebug) {
                printf("terminating because OOB; at cell [%d, %d] and screen coords [%.2f, %.2f]\n", cell.x, cell.y, windowSpacePos.x, windowSpacePos.y);
            }

            break;
        }

        float depthSample = hiDepthTexture.Load(int3(cell, currentLevel));
        bool intersect = depthSample > 0.0 && depthSample > windowSpacePos.z;

        if (writeDebug) {
            if (intersect) printf("intersection; ");
            else printf("no intersection; ");

            printf("current level is %u, with cell position [%d, %d] and screen coords [%.2f, %.2f]\n", currentLevel, cell.x, cell.y, windowSpacePos.x, windowSpacePos.y);
            hiZDebugTexture[currentLevel].Store(cell, 1);
        }

        if (intersect) {
            if (currentLevel == 0) {
                // intersection = float3(cell.xy, windowSpacePos.z) / float3(ap.game.renderSize, 1.0);
                intersection = windowSpacePos / float3(ap.game.renderSize, 1.0);
                return true;
            }

            // advance only until the itnersection with the sampled depth plane, instead of the calculated cell advance dist
            // aka the farthest we can go from the currently known information (sampled depth)
            float distToSampledDepth = max(0.0, (depthSample - previousWindowSpacePos.z) / windowSpaceDir.z);
            windowSpacePos = previousWindowSpacePos + distToSampledDepth * windowSpaceDir;
            // windowSpacePos = previousWindowSpacePos;

            currentLevel -= 1;

            // recalculate distances and sizes based on level
            getHiZTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);
        } else {
            bool parentCellAdvanced = any((previousCell >> 1) != (cell >> 1));

            // go up a level if outside the confines of the parent cell we descended from
            if (currentLevel < maxLevel && parentCellAdvanced) {
                currentLevel += 1;
                getHiZTraversalDists(windowSpacePos, windowSpaceDir, currentLevel, stepDir, stepSizes, nextDist, cell);
            }
        }
    }

    return false;
}

void getVoxelTraversalDists(
    float3 pos, 
    float3 dir,
    uint level,
    out float3 stepDir,
    out float3 stepSizes,
    out float3 nextDist,
    out int3 cell
) {
    stepDir = sign(dir);
    
    stepSizes = 1.0 / abs(dir); 
    nextDist = (stepDir * 0.5 + 0.5 - fract(pos)) / dir;

    cell = int3(floor(pos));
}

public struct VoxelHit {
    public float3 pos;
    public float3 normal;
}

public bool raytraceVoxelMap(
    float3 pos,
    float3 dir,
    uint steps,
    // float maxT,
    out VoxelHit hit,
) {
    hit.pos = pos;
    
    float3 stepDir, stepSizes, nextDist;
    int3 cell;

    getVoxelTraversalDists(pos, dir, 0, stepDir, stepSizes, nextDist, cell);

    for (uint i = 0; i < steps; i++) {
        float closestDist = min3(nextDist.x, nextDist.y, nextDist.z);

        hit.pos += dir * closestDist;

        float3 stepAxis = float3(nextDist <= float3(closestDist));

        cell += int3(stepAxis * stepDir);

        nextDist -= closestDist;
        nextDist += stepSizes * stepAxis;

        hit.normal = stepAxis;

        if (ap.blocks[ap.voxel[cell]].isFullBlock) {
            hit.pos -= ap.camera.position;
            hit.normal *= -stepDir;
            
            return true;
        }
    }

    return false;
}

