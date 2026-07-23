import aperture;

import lib.space;
import lib.random;
import lib.exposure;
import lib.color;
import lib.tonemap;

extern static const bool showHistogram = false;
extern static const int histogramBins = 256;
extern static const float minLuminance = 0.000001;
extern static const float maxLuminance = 2.0;

StructuredBuffer<uint> histogram;

Texture2D outputTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    float3 color = outputTexture.SampleLevel(apt_linearSampler, uv, 3.0).rgb;
    
    color = acesFitTonemap(color * 3.0);
    
    color = gammaCorrectSrgb(color);

    // deubg view for histogram
    if (showHistogram) {
        float debugViewAlpha = 0.7;

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

            float3 histogramColor = scaledPos.y < height ? float3(1.0) : float3(0.0);
            
            color = lerp(color, histogramColor, debugViewAlpha);
        }
    }

    return saturate(float4(color, 1.0));
}
