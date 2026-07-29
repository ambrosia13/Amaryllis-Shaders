import aperture;

import lib.sample;

RWTexture2D targetTexture;
Texture2D bloomUpsampleTexture;

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void main(uint3 globalInvocationId: SV_DispatchThreadID) {
    if (any(globalInvocationId.xy >= ap.game.renderSize)) {
        return;
    }

    float2 uv = float2(globalInvocationId.xy) / ap.game.renderSize;
    float2 distance = 1.0 / ap.game.renderSize;

    float4 color = targetTexture[globalInvocationId.xy];
    float4 bloomyColor = frx_sampleTent(bloomUpsampleTexture, uv, distance, 0);

    float bloomAmount = 0.2;

    targetTexture.Store(globalInvocationId.xy, lerp(color, bloomyColor, bloomAmount));
}
