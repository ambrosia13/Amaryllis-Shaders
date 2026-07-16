package config;

import org.joml.Vector4f;

import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import mapping.BlockIdMapping;
import util.SwapTexture2D;

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
    
    public final OutputsAux solidAux;
    public final OutputsAux translucentAux;

    public Gbuffer(PipelineConfig pipeline, SwapTexture2D mainTextures) {
        // since the solid and translucent passes write to the main textures, clear them
        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), mainTextures.a);
        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), mainTextures.b);

        solidAux = new OutputsAux("solid", pipeline, true);
        translucentAux = new OutputsAux("translucent", pipeline, true);

        var replaceBlendMode = new BlendMode(
            BlendFactors.ONE, 
            BlendFactors.ZERO, 
            BlendFactors.ONE, 
            BlendFactors.ZERO
        );

        ProgramUsage[] deferredTargets = { ProgramUsage.BASIC };
        ProgramUsage[] forwardTargets = { ProgramUsage.TRANSLUCENT };

        for (var target : deferredTargets) {
            var builder = pipeline.object(target, "program/object/basic", "GbufferShader")
                .exportFloat("skyCubemapMips", Sky.cubemapMips)
                .exportInt("shadowCascadeCount", Shadow.cascadeCount)
                .exportInt("shadowMapSize", Shadow.size)
                // this is the first write, so no need to flip
                .writes("color", mainTextures.overwrite())
                .writes("matNormals", solidAux.matNormalsTexture)
                .writes("matPbr", solidAux.matPbrTexture)
                .writes("matLight", solidAux.matLightTexture);
            
            BlockIdMapping.exportAllIds(builder);
        }

        // do deferred shading in pre-translucent stage
        var deferredBuilder = pipeline.stage(ProgramStage.PRE_TRANSLUCENT)
            .composite("deferred", "program/object/deferred", "main")
            // reads from a and writes to b
            .writes("color", mainTextures.write())
            .overrideObject("solidAlbedoTexture", mainTextures.read().name())
            .exportFloat("skyCubemapMips", Sky.cubemapMips)
            .exportInt("shadowCascadeCount", Shadow.cascadeCount)
            .exportInt("shadowMapSize", Shadow.size);
                 
        BlockIdMapping.exportAllIds(deferredBuilder);

        // flip after deferred pass, since it read from a and wrote to b
        mainTextures.flip();

        for (var target : forwardTargets) {
            // albedo should blend normally, but aux data should not blend
            var builder = pipeline.object(target, "program/object/basic", "GbufferShader")
                .exportFloat("skyCubemapMips", Sky.cubemapMips)
                .exportInt("shadowCascadeCount", Shadow.cascadeCount)
                .exportInt("shadowMapSize", Shadow.size)
                // since the object shader doesn't read from a texture, but just blends into the existing texture,
                // don't use the flipped one for writing
                .writes("color", mainTextures.overwrite())
                .writes("matNormals", solidAux.matNormalsTexture, replaceBlendMode)
                .writes("matPbr", solidAux.matPbrTexture, replaceBlendMode)
                .writes("matLight", solidAux.matLightTexture, replaceBlendMode);

            BlockIdMapping.exportAllIds(builder);
        }


    }

}