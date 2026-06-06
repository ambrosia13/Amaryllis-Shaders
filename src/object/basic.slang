import aperture;
import object_shader;
import settings; // Contains your shader settings, both realtime and compile time.

// import lib.shadows;
import lib.material;

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
}

struct GbufferShader : Shader<VertexOutput, FragmentOutput> {
    static void emitVertex(Vertex v, out VertexOutput output, out float4 pos) {
        pos = v.pos();

        output.uv = v.uv();
        output.pos = v.pos().xyz;
        output.color = v.color();
        output.normal = v.normal().orElse(-normalize(pos.xyz));
        output.light = float3(v.lightCoord(), v.vertexAO().orElse(1.0));
    }

    static FragmentOutput shadeSurface(PixelData objectData, VertexOutput input) {
        float4 color = input.color;

        Material mat = Material(
            input.normal, // vertex normal
            input.normal, // fragment normal

            0.04, // reflectance
            1.0, // roughness
            iris_isCutout ? 1.0 : 0.0, // sss amount
            false, // isWater

            input.light.x, // blocklight
            input.light.y, // skylight
            input.light.z, // ambient occlusion
            0.0 // emission
        );

        if (let texture = objectData.albedo()) { // Since `albedo()` returns an Optional<Sampleable>, this is one of a few ways to get the true type. You can also do albedo().hasValue and albedo().value, of course.
            color *= texture.sampleTexture(input.uv); // Some objects simply don't have a texture, such as clouds.
        }

        // This is equivalent to `if (objectIsCutout && alpha < 0.1) discard;`. It will determine if the object needs it.
        ap.discardCutout(color);

        // // Refer to your `TemplatePackSettings`. Hit that `Generate Shader Settings` button there to regenerate the GPU-side.
        // if (userSettings.shadows) {
        //     color.rgb *= lerp(0.35, 1.0, shadowVisibility(input.pos));
        // }

        FragmentOutput output;

        output.matNormals = float4(input.normal, 1.0);
        output.matPbr = mat.packPbr();
        output.matLight = mat.packLight();

        output.color = color;

        return output;
    }
}