/*
    This bloom method is based on the classic COD bloom, and my implementation of it, which is largely the same as in Forget-me-not Shaders,
    is historically referenced from FREX/Canvas's bloom implementation, which is released under the GNU LGPL license, although all code here
    other than the upsample and downsample filters is written by me.
*/

import aperture;

extern static const int lod;

SamplerState bloomSampler;
Texture2D inputTexture;

struct FragmentOutput {
    float4 color;
}

// See this file's header.
// 
// Temporally stable box filter, as described by Jorge Jiminez, 2014
// http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
float4 frx_sample13(Texture2D tex, float2 uv, float2 distance, float lod) {
	float4 a = tex.SampleLevel(bloomSampler, uv + distance * float2(-1.0, -1.0), lod);
	float4 b = tex.SampleLevel(bloomSampler, uv + distance * float2(0.0, -1.0), lod);
	float4 c = tex.SampleLevel(bloomSampler, uv + distance * float2(1.0, -1.0), lod);
	float4 d = tex.SampleLevel(bloomSampler, uv + distance * float2(-0.5, -0.5), lod);
	float4 e = tex.SampleLevel(bloomSampler, uv + distance * float2(0.5, -0.5), lod);
	float4 f = tex.SampleLevel(bloomSampler, uv + distance * float2(-1.0, 0.0), lod);
	float4 g = tex.SampleLevel(bloomSampler, uv, lod);
	float4 h = tex.SampleLevel(bloomSampler, uv + distance * float2(1.0, 0.0), lod);
	float4 i = tex.SampleLevel(bloomSampler, uv + distance * float2(-0.5, 0.5), lod);
	float4 j = tex.SampleLevel(bloomSampler, uv + distance * float2(0.5, 0.5), lod);
	float4 k = tex.SampleLevel(bloomSampler, uv + distance * float2(-1.0, 1.0), lod);
	float4 l = tex.SampleLevel(bloomSampler, uv + distance * float2(0.0, 1.0), lod);
	float4 m = tex.SampleLevel(bloomSampler, uv + distance * float2(1.0, 1.0), lod);

	float2 div = (1.0 / 4.0) * float2(0.5, 0.125);

	float4 o = (d + e + i + j) * div.x;
	o += (a + b + g + f) * div.y;
	o += (b + c + h + g) * div.y;
	o += (f + g + l + k) * div.y;
	o += (g + h + m + l) * div.y;

	return o;
}

[[shader("pixel")]]
FragmentOutput downsampleFirst(float2 pos: SV_Position) {
    int2 passSize = ap.game.renderSize >> lod;

    float2 uv = pos / passSize;
    float2 distance = 2.0 / passSize;

    // return FragmentOutput(float4(uv, 0.0, 1.0));
    return FragmentOutput(max(float4(0.0), frx_sample13(inputTexture, uv, distance, max(0, lod - 1))));
}

[[shader("pixel")]]
FragmentOutput downsample(float2 pos: SV_Position) {
    // add 1 to the lod because the base lod is already half the screen size
    int2 passSize = ap.game.renderSize >> (lod + 1);

    float2 uv = pos / passSize;
    float2 distance = 2.0 / passSize;

    return FragmentOutput(frx_sample13(inputTexture, uv, distance, max(0, lod - 1)));
}
