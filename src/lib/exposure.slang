/*
    Some equations here are referenced from https://google.github.io/filament/Filament.md.html.
*/

public module exposure;

import lib.math;

public uint getBinIndex(float luminance, float minLum, float maxLum, uint bins) {
    const float minLogLuminance = log2(minLum);
    const float maxLogLuminance = log2(maxLum);

    if (luminance < minLum) {
        // avoid taking the log of 0
        return 0;
    }
    
    float logLuminance = clamp(log2(luminance), minLogLuminance, maxLogLuminance);

    float normalizedLuminance = (logLuminance - minLogLuminance) / (maxLogLuminance - minLogLuminance);

    uint binIndex = uint(floor(normalizedLuminance * bins));
    binIndex = min(binIndex, bins - 1);

    return binIndex;
}


public float manualEV100(float aperture, float shutterSpeed, float iso) {
    return log2(pow2(aperture) / shutterSpeed * 100.0 / iso);
}

public float automaticEV100(float averageLuminance, float exposureCompensation) {
    const float S = 100; // sensor sensitivity or ISO setting
    const float K = 12.5; // light meter calibration constant, realistic scale (assumes realistic lighting values, which we don't have)

    return log2(averageLuminance * S / K) - exposureCompensation;
}

public float getExposure(float ev100) {
    const float q = 0.65; // the lens/vignette attenuation
    const float S = 100; // iso setting

    // where does the number 78 come from? google filament doesn't seem to mention it
    // but it seems like it's based on saturation-based automatic exposure
    return 1.0 / (pow(2.0, ev100) * (78.0 / (q * S)));
}
