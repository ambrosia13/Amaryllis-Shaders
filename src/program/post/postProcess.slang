import aperture;

import lib.exposure;
import lib.color;
import lib.palette;
import lib.noise;

StructuredBuffer<float> meteredLuminance;

Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    float2 uv = pos / ap.game.renderSize;

    float3 color = inputTexture.Sample(apt_linearSampler, uv).rgb;

    float purkinjeAmount = exp(-luminance(color) * 400.0);

    float3 darkVisionColor = purkinjeShift(color);
    color.rgb = lerp(color.rgb, darkVisionColor, purkinjeAmount);

    float sceneLuminance = meteredLuminance[0];
    sceneLuminance = clamp(sceneLuminance, 0.008, 0.15);

    float ev100 = automaticEV100(sceneLuminance, 0.0);
    // ev100 = clamp(ev100, 3.0, 20.0);

    float exposure = getExposure(ev100);

    // float2 squareUv = uv * float2(1.0, float(ap.game.renderSize.y) / ap.game.renderSize.x);
    // squareUv += ap.game.renderSize.y * (((ap.timing.frameCounter / 2) % 8));
    // float grain = fbmSimplex2D(squareUv * 300.0, 3, 1.5, 0.0);

    // // may not be the best way to apply, but gives more prominent look in dark areas
    // color += grain * 0.00025;

    color *= exposure;

    float luminance = luminance(color);

    float shadowMask = smoothstep(0.025, 0.0, luminance);
    float highlightMask = smoothstep(0.05, 0.2, luminance);
    float midtoneMask = 1.0 - shadowMask - highlightMask;

    // color = lerp(color, float3(0, 0, 1), shadowMask);
    // color = lerp(color, float3(0, 1, 0), midtoneMask);
    // color = lerp(color, float3(1, 0, 0), highlightMask);

    return FragmentOutput(float4(color, 1.0));
}
