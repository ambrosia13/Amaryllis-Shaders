/*
    This bloom method is based on the classic COD bloom, and my implementation of it, which is largely the same as in Forget-me-not Shaders,
    is historically referenced from FREX/Canvas's bloom implementation, which is released under the GNU LGPL license, although all code here
    other than the upsample and downsample filters is written by me.
*/

import aperture;

import lib.sample;

extern static const int mipCount;
extern static const int lod;

Texture2D bloomDownsampleTexture;
Texture2D bloomUpsampleTexture;

struct FragmentOutput {
    float4 color;
}

[[shader("pixel")]]
FragmentOutput upsampleFirst(float2 pos: SV_Position) {
    // add 1 to the lod because the base lod is already half the screen size
    int2 passSize = ap.game.renderSize >> (lod + 1);

    float2 uv = pos / passSize;
    float2 distance = 1.0 / passSize;

    float contrib = 1.0 / mipCount;

    // sample from highest lod of downsample texture to start accumulating
    return FragmentOutput(contrib * frx_sampleTent(bloomDownsampleTexture, uv, distance, lod));
}

[[shader("pixel")]]
FragmentOutput upsample(float2 pos: SV_Position) {
    // add 1 to the lod because the base lod is already half the screen size
    int2 passSize = ap.game.renderSize >> (lod + 1);

    float2 uv = pos / passSize;
    float2 distance = 2.0 / passSize;

    float contrib = 1.0 / mipCount;

    // sum of accumulation so far (upsampleTexture lod + 1) and current downsample level (lod)
    return FragmentOutput(
        contrib * frx_sampleTent(bloomDownsampleTexture, uv, distance, lod) +
        bloomUpsampleTexture.SampleLevel(apt_linearSampler, uv, lod + 1)
    );
}
