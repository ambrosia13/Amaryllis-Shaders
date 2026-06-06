package config;

import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;

public class Gbuffer {
    // we need high dynamic range in RGB, but we also need the alpha channel intact, so use rgba16f
    public static final TextureFormat forwardLitTextureFormat = TextureFormat.RGBA16_SFLOAT;
    
    public static final TextureFormat albedoTextureFormat = TextureFormat.RGBA8_UNORM;
    public static final TextureFormat matNormalsTextureFormat = TextureFormat.RGBA16_SNORM;
    public static final TextureFormat matPbrTextureFormat = TextureFormat.RGBA8_UINT;
    public static final TextureFormat matLightTextureFormat = TextureFormat.RGBA8_UNORM;

    public static class OutputsAux {
        public final Texture2D matNormalsTexture;
        public final Texture2D matPbrTexture;
        public final Texture2D matLightTexture;

        public OutputsAux(String targetPrefix, PipelineConfig pipeline, boolean clear) {
            matNormalsTexture = pipeline.texture2D(targetPrefix + "MatNormalsTexture", matNormalsTextureFormat)
                .renderSize()
                .create();
                
            matPbrTexture = pipeline.texture2D(targetPrefix + "MatPbrTexture", matPbrTextureFormat)
                .renderSize()
                .create();
                
            matLightTexture = pipeline.texture2D(targetPrefix + "MatLightTexture", matLightTextureFormat)
                .renderSize()
                .create();
            
            if (clear) {
                pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(matNormalsTexture);
                pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(matPbrTexture);
                pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(matLightTexture);            
            }
        }
    }

    public final Texture2D solidAlbedoTexture;
    public final Texture2D translucentAlbedoTexture;
    
    public final OutputsAux solidAux;
    public final OutputsAux translucentAux;

    public Gbuffer(PipelineConfig pipeline) {
        solidAlbedoTexture = pipeline.texture2D("solidAlbedoTexture", albedoTextureFormat)
            .renderSize()
            .create();

        // translucents are forward rendered, so use a higher precision texture format
        translucentAlbedoTexture = pipeline.texture2D("translucentAlbedoTexture", forwardLitTextureFormat)
            .renderSize()
            .create();

        pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(solidAlbedoTexture);
        pipeline.stage(ProgramStage.PRE_RENDER).clearToWhite(translucentAlbedoTexture);

        solidAux = new OutputsAux("solid", pipeline, true);
        translucentAux = new OutputsAux("translucent", pipeline, true);

        pipeline.object(ProgramUsage.BASIC, "object/basic", "GbufferShader")
            .writes("color", solidAlbedoTexture)
            .writes("matNormals", solidAux.matNormalsTexture)
            .writes("matPbr", solidAux.matPbrTexture)
            .writes("matLight", solidAux.matLightTexture);

        pipeline.object(ProgramUsage.TRANSLUCENT, "object/basic", "GbufferShader")
            .writes("color", translucentAlbedoTexture)
            .writes("matNormals", translucentAux.matNormalsTexture)
            .writes("matPbr", translucentAux.matPbrTexture)
            .writes("matLight", translucentAux.matLightTexture);
    }
}