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

extern static const float percentile = 0.75; // default median

StructuredBuffer<uint> histogram;
RWStructuredBuffer<float> meteredLuminance;

// local histogram written to by each local workgroup before merging with the global histogram
// note that the blog post uses a bin count equal to the workgroup size, rather than an independent number
groupshared uint localHistogram[histogramBins];

void writeMeteredLuminanceFromBin(float bin) {
    float minLogLuminance = log2(minLuminance);
    float maxLogLuminance = log2(maxLuminance);

    float avgLogLum = minLogLuminance + bin / (histogramBins - 1) * (maxLogLuminance - minLogLuminance);
    float meteredLum = exp2(avgLogLum);

    float previousLum = meteredLuminance[0];

    float deltaTime = ap.timing.lastFrameTime;
    float adaptationTime = 1.0;
    float smoothingFactor = 1.0 - exp(-deltaTime / adaptationTime);

    if (ap.timing.frameCounter > 1) {
        meteredLuminance[0] = max(0.0, lerp(previousLum, meteredLum, smoothingFactor));
    } else {
        meteredLuminance[0] = meteredLum;
    }
}

// TODO: see if 16x16x1 workgroups can be used
[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void averageLuminance(uint3 globalInvocationId: SV_DispatchThreadID, uint localInvocationIndex: SV_GroupIndex) {
    for (uint i = localInvocationIndex; i < histogramBins; i += 64) {
        /*
            From a comment under the blog post:

            "Can you explain why you are multiplying by the local index in this equation?"

            > "He does this because he wants to sum up the luminance of this bin. The luminance of a bin in the histogramm is 
            the count of its value (countForThisBin) multiplicated with the luminance of this bin (localIndex/gl_LocalInvocationIndex). 
            In the next step he adds up all the bins to get the total sum of logLuminance in this picture. And after this he devides 
            it by the number of all pixels that have a luminance greater than 1. I struggeled with this question as well but it makes 
            total sense XD."

            So I guess we're multiplying by the bin index so that we can recover the total luminance of this bin later?
        */
        localHistogram[i] = histogram[i] * i;
    }

    GroupMemoryBarrierWithGroupSync();

    for (uint cutoff = histogramBins >> 1; cutoff > 0; cutoff >>= 1) {
        for (uint i = localInvocationIndex; i < histogramBins; i += 64) {
            if (i < cutoff)
                localHistogram[i] += localHistogram[i + cutoff];
        }

        GroupMemoryBarrierWithGroupSync();
    }

    if (localInvocationIndex == 0) {
        float weightedLogAverage = (localHistogram[0] / max(float(ap.game.renderSize.x * ap.game.renderSize.y - histogram[0]), 1.0)) - 1.0;

        uint pixelCount = ap.game.renderSize.x * ap.game.renderSize.y;
        float averageBin = float(localHistogram[0]) / pixelCount;

        writeMeteredLuminanceFromBin(averageBin);
    }
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void percentileLuminance(uint3 globalInvocationId: SV_DispatchThreadID, uint localInvocationIndex: SV_GroupIndex) {
    if (localInvocationIndex == 0) {
        uint pixelCount = ap.game.renderSize.x * ap.game.renderSize.y;
        uint target = uint(pixelCount * percentile);        

        uint bin = 0;
        uint count = 0;

        for (bin = 0; bin < histogramBins; bin++) {
            count += histogram[bin];

            if (count >= target) break;
        }

        writeMeteredLuminanceFromBin(float(bin));
    }
}


