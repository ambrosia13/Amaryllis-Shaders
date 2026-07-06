/*
    To implement histogram-based auto exposure, I followed the extremely helpful guide over at https://bruop.github.io/exposure/.
    The code and general algorithm is referenced from the blog post, but is written by me.

    Additionally, for further reading and more detailed equations, I referred to https://google.github.io/filament/Filament.md.html.
*/

import aperture;

import lib.util;

extern static const int histogramBins;

// together, these define the dynamic range of the sensor
extern static const float minLuminance; // assumed greater than zero
extern static const float maxLuminance;

RWStructuredBuffer<uint> histogram;

Texture2D inputTexture;

// local histogram written to by each local workgroup before merging with the global histogram
// note that the blog post uses a bin count equal to the workgroup size, rather than an independent number
groupshared uint localHistogram[histogramBins];

uint getBinIndex(float3 color) {
    const float minLogLuminance = log2(minLuminance);
    const float maxLogLuminance = log2(maxLuminance);

    float luminance = luminance(color);
    if (luminance < minLuminance) {
        // avoid taking the log of 0
        return 0;
    }
    
    float logLuminance = clamp(log2(luminance), minLogLuminance, maxLogLuminance);

    float normalizedLuminance = (logLuminance - minLogLuminance) / (maxLogLuminance - minLogLuminance);

    uint binIndex = uint(floor(normalizedLuminance * histogramBins));
    binIndex = min(binIndex, histogramBins - 1);

    return binIndex;
}

[[numthreads(64, 1, 1)]]
[[shader("compute")]]
void clearHistogram(uint localInvocationIndex: SV_GroupIndex) {
    for (uint i = localInvocationIndex; i < histogramBins; i += 64) {
        histogram[i] = 0;
    }
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void populateHistogram(uint3 globalInvocationId: SV_DispatchThreadID, uint localInvocationIndex: SV_GroupIndex) {
    // initialize the local histogram first, assume histogramBins is a multiple of 64 to simplify math
    for (uint i = localInvocationIndex; i < histogramBins; i += 64) {
        localHistogram[i] = 0;
    }

    GroupMemoryBarrierWithGroupSync();

    if (globalInvocationId.x < ap.game.renderSize.x && globalInvocationId.y < ap.game.renderSize.y) {
        float3 color = inputTexture[globalInvocationId.xy].rgb;
        uint binIndex = getBinIndex(color);

        __atomic_add(localHistogram[binIndex], 1);
    }

    GroupMemoryBarrierWithGroupSync();

    for (uint i = localInvocationIndex; i < histogramBins; i += 64) {
        __atomic_add(histogram[i], localHistogram[i]);
    }
}
