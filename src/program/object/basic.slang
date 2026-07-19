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

// built-in pbr textures
Texture2D blockAtlasN;
Texture2D blockAtlasS;

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
    float4 tangent;
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
        output.tangent = v.tangent().orElse(float4(0));
        output.light = float3(v.lightCoord(), v.vertexAO().orElse(1.0));
        output.blockId = v.blockID().hasValue ? v.blockID().value.data.customId : 0;
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput input) {
        float4 color = input.color;

        // needed until aperture gives light attributes in 0-1 range
        const float lmcoordLowerBound = 1.0 / 32.0;
        const float lmcoordUpperBound = 31.0 / 32.0;

        float reflectance = 0.04;
        float roughness = 1.0;
        float emission = 0.0;
        float sssAmount = input.blockId == SURFACE_FOLIAGE_ID || input.blockId == FOLIAGE_ID ? 1.0 : 0.0;
        float ao = input.light.z;

        float3 fragNormal = input.normal;

        if (objectData.albedo().hasValue) {
            float4 labNormalSample = blockAtlasN.sampleNearest(input.uv);
            float4 labSpecularSample = blockAtlasS.sampleNearest(input.uv);

            labNormalSample.xy = labNormalSample.xy * 2.0 - 1.0;

            float3 bitangent = cross(input.normal, input.tangent.xyz) * -sign(input.tangent.w);
            float3x3 tbn = float3x3(input.tangent.xyz, bitangent, input.normal);

            float3 tangentSpaceNormal = float3(
                labNormalSample.x,
                labNormalSample.y,
                sqrt(1.0 - dot(labNormalSample.xy, labNormalSample.xy))
            );

            fragNormal = mul(tangentSpaceNormal, tbn);

            ao *= labNormalSample.z;

            roughness = pow2(1.0 - labSpecularSample.x);
            reflectance = linearstep(0.0, 229.0 / 255.0, labSpecularSample.y);
            sssAmount = linearstep(65.0 / 255.0, 1.0, labSpecularSample.z);
            emission = labSpecularSample.w;
        }

        Material mat = Material(
            input.normal, // vertex normal
            fragNormal,

            reflectance,
            roughness,
            sssAmount,
            input.blockId == WATER_ID, // isWater

            linearstep(lmcoordLowerBound, lmcoordUpperBound, input.light.x), // blocklight
            linearstep(lmcoordLowerBound, lmcoordUpperBound, input.light.y), // skylight
            ao, // ambient occlusion
            emission
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

        if (iris_isTranslucent) {
            // convert to linear srgb before lighting
            color.rgb = linearizeSrgb(color.rgb);

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