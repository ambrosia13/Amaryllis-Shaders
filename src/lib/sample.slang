public module sample;

import aperture;

// See the header of program/bloom/upsample.slang.
// 
// Used for bloom upsample, as described by Jorge Jiminez, 2014
// http://www.iryoku.com/next-generation-post-processing-in-call-of-duty-advanced-warfare
public float4 frx_sampleTent(Texture2D tex, float2 uv, float2 distance, float lod) {
	float4 d = distance.xyxy * float4(1.0, 1.0, -1.0, 0.0);

	float4 sum = tex.SampleLevel(apt_linearSampler, uv - d.xy, lod)
               + tex.SampleLevel(apt_linearSampler, uv - d.wy, lod) * 2.0
               + tex.SampleLevel(apt_linearSampler, uv - d.zy, lod)
               + tex.SampleLevel(apt_linearSampler, uv + d.zw, lod) * 2.0
               + tex.SampleLevel(apt_linearSampler, uv       , lod) * 4.0
               + tex.SampleLevel(apt_linearSampler, uv + d.xw, lod) * 2.0
               + tex.SampleLevel(apt_linearSampler, uv + d.zy, lod)
               + tex.SampleLevel(apt_linearSampler, uv + d.wy, lod) * 2.0
               + tex.SampleLevel(apt_linearSampler, uv + d.xy, lod);

	return sum * (1.0 / 16.0);
}
