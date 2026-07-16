import aperture;
import object_shader;
import settings; // Contains your shader settings, both realtime and compile time.

import lib.material;
import lib.lighting;
import lib.color;
import lib.math;
import lib.blockIds;

Texture2D transmittanceLookupTexture;
TextureCube skyCubemapTexture;

struct FragmentOutput {
    float4 color;

    float4 matNormals;
    uint4 matPbr;
    float4 matLight;
}

struct VertexOutput {
    float3 pos;
    float4 color : COLOR;
    float2 uv : TEXCOORD;
    float3 normal;
    float3 light;
    nointerpolation int blockId;
}

struct GbufferShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex v, out VertexOutput output, out float4 pos) {
        pos = v.pos();

        output.uv = v.uv();
        output.pos = v.pos().xyz;
        output.color = v.color();
        output.normal = v.normal().orElse(-normalize(pos.xyz));
        output.light = float3(v.lightCoord(), v.vertexAO().orElse(1.0));
        output.blockId = v.blockID().hasValue ? v.blockID().value.data.customId : 0;
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput input) {
        float4 color = input.color;

        // needed until aperture gives light attributes in 0-1 range
        const float lmcoordLowerBound = 1.0 / 32.0;
        const float lmcoordUpperBound = 31.0 / 32.0;

        Material mat = Material(
            input.normal, // vertex normal
            input.normal, // fragment normal

            0.04, // reflectance
            1.0, // roughness
            input.blockId == SURFACE_FOLIAGE_ID || input.blockId == FOLIAGE_ID ? 1.0 : 0.0, // sss amount
            input.blockId == WATER_ID, // isWater

            linearstep(lmcoordLowerBound, lmcoordUpperBound, input.light.x), // blocklight
            linearstep(lmcoordLowerBound, lmcoordUpperBound, input.light.y), // skylight
            input.light.z, // ambient occlusion
            0.0 // emission
        );

        // provides more natural looking falloff
        mat.skyLight *= mat.skyLight;

        if (let texture = objectData.albedo()) { // Since `albedo()` returns an Optional<Sampleable>, this is one of a few ways to get the true type. You can also do albedo().hasValue and albedo().value, of course.
            color *= texture.sampleTexture(input.uv); // Some objects simply don't have a texture, such as clouds.
        }
        
        if (input.blockId == WATER_ID) {
            color.rgb = input.color.rgb;
            color.a = 0.01;
        }

        // This is equivalent to `if (objectIsCutout && alpha < 0.1) discard;`. It will determine if the object needs it.
        ap.discardCutout(color);

        // convert to linear srgb
        color.rgb = linearizeSrgb(color.rgb);

        if (iris_isTranslucent) {
            int2 coord = int2(objectData.screenPos.xy);

            // color.rgb = float3(saturate(dot(mat.fragNormal, normalize(ap.celestial.sunPosition))));
            color.rgb *= lighting(
                transmittanceLookupTexture,
                skyCubemapTexture,
                coord,
                input.pos, 
                mat
            );

            // color.rgb = input.pos / 100.0;
        }

        FragmentOutput output;

        output.matNormals = mat.packNormals();
        output.matPbr = mat.packPbr();
        output.matLight = mat.packLight();

        output.color = color;

        return output;
    }
}