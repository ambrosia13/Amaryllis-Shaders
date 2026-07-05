import aperture;
import object_shader;

// This will not be documented. See basic.slang for what everything here does.

struct ShadowOut {}

struct ShadowVOut {
    float2 uv : TEXCOORD;
}

struct ShadowShader : Shader<ShadowVOut, ShadowOut> {
    static void emitVertex(Vertex v, out ShadowVOut data, out float4 pos) {
        pos = v.pos();
        data = ShadowVOut(v.uv());
    }

    static ShadowOut shadeSurface(PixelData objectData, ShadowVOut s) {
        if (let texture = objectData.albedo()) {
            ap.discardCutout(texture.sampleTexture(s.uv));
        }
        return ShadowOut();
    }
}
