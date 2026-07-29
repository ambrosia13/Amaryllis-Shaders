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
Texture2D<uint> hiZDebugTexture;

[[shader("pixel")]]
float4 main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;
    uint2 coord = uint2(pos);

    float3 color = outputTexture.SampleLevel(apt_linearSampler, uv, 3.0).rgb;
    
    float3 debugColors[] = {
        float3(1, 0, 0),
        float3(0, 1, 0),
        float3(0, 0, 1),
        float3(1, 1, 0),
        float3(0, 1, 1),
        float3(1, 0, 1),
        float3(0.75, 0.25, 0),
        float3(0, 0.25, 0.75),
        float3(0.25, 0.75, 0),
        float3(0, 0.75, 0.25),
    };

    var random = Random<Pcg>(Pcg(5353));
    
    for (int i = 9; i >= 0; i--) {
        var flag = hiZDebugTexture.Load(int3(coord >> i, i));

        if (flag == 1) {
            // (float3(random.getFloat(), random.getFloat(), random.getFloat()))
            color = lerp(color, debugColors[i], 1.0);
        }

        if (flag == 2 && i < 4) {
            color = lerp(color, float3(1, 0, 0), 1);
        }
    }
    
    color = mul(AP1toSRGB, color);
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
