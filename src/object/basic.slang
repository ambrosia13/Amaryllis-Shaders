import aperture; // Required import. Always.
import object_shader; // Required import for object shaders. Not recommended otherwise.
import settings; // Contains your shader settings, both realtime and compile time.

// Imports `helpers/shadows.slang`, since it is declared with `public module shadows`. See the Slang user guide for more info if confused.
import lib.shadows;

// What you intend to output (color). Name these with what you have put as the bindings in Java.
struct Out {
    float4 color;
}

// What you intend to pass from the vertex shader to the fragment shader. Can have whatever you want.
struct VertexOutput {
    float2 uv : TEXCOORD; // This : TEXCOORD at the end is called a "semantic". It is used to hint to Aperture what it is. Not required, but recommended. In the future, a list of recommended semantics will be provided.
    float3 pos;
    float4 color : COLOR;
}

struct BasicShader : Shader<VertexOutput, Out> {
    static void emitVertex(Vertex v, out VertexOutput output, out float4 pos) {
        // Generally, `v.pos()` will be in camera-relative world space. This might not be the case for all objects in beta 1, please report if this becomes a major issue for you.
        pos = v.pos();

        output.uv = v.uv();
        output.pos = v.pos().xyz;
        output.color = v.color();
    }

    static Out shadeSurface(PixelData objectData, VertexOutput input) {
        float4 color = input.color;

        if (let texture = objectData.albedo()) { // Since `albedo()` returns an Optional<Sampleable>, this is one of a few ways to get the true type. You can also do albedo().hasValue and albedo().value, of course.
            color *= texture.sampleTexture(input.uv); // Some objects simply don't have a texture, such as clouds.
        }

        // This is equivalent to `if (objectIsCutout && alpha < 0.1) discard;`. It will determine if the object needs it.
        ap.discardCutout(color);

        // Refer to your `TemplatePackSettings`. Hit that `Generate Shader Settings` button there to regenerate the GPU-side.
        if (userSettings.shadows) {
            color.rgb *= lerp(0.35, 1.0, shadowVisibility(input.pos));
        }

        return { color }; // Equivalent to return Out(color).
    }
}