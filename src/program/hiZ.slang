import aperture;

extern static const uint srcLod;
extern static const uint dstLod;

RWTexture2D<float> hiDepthTexture[];

void copyFirstDepth(uint3 globalInvocationId: SV_DispatchThreadID) {
    if (all(globalInvocationId.xy < ap.game.renderSize))
        hiDepthTexture[0].Store(globalInvocationId.xy, ap.depth[globalInvocationId.xy]);
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void depthDownsample(uint3 globalInvocationId: SV_DispatchThreadID, uint localInvocationIndex: SV_GroupIndex) {
    uint blockSize = 1 << (dstLod - srcLod); // how many texels to take the max of
    uint2 dstSize = ap.game.renderSize >> dstLod;
    
    if (any(globalInvocationId.xy >= dstSize)) {
        return;
    }

    uint2 srcBase = globalInvocationId.xy << (dstLod - srcLod);

    float maxDepth = float.minValue;

    for (uint x = 0; x < blockSize; x++) {
        for (uint y = 0; y < blockSize; y++) {
            maxDepth = max(maxDepth, hiDepthTexture[srcLod].Load(srcBase, uint2(x, y)));
        }
    }

    hiDepthTexture[dstLod].Store(globalInvocationId.xy, maxDepth);
}
