package config;

import org.joml.Vector4f;

import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import mapping.BlockIdMapping;
import util.SwapTexture2D;
import util.Util;

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

    public final Texture2D shadowFactor;

    public Gbuffer(Screen screen, PipelineConfig pipeline, SwapTexture2D mainTextures) {
        // since the solid and translucent passes write to the main textures, clear them
        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), mainTextures.a);
        pipeline.stage(ProgramStage.PRE_RENDER).clearTo(new Vector4f(0.0f), mainTextures.b);

        solidAux = new OutputsAux("solid", pipeline, true);
        translucentAux = new OutputsAux("translucent", pipeline, true);

        shadowFactor = pipeline.texture2D("shadowFactorTexture", TextureFormat.R8_SNORM)
            .renderSize()
            .create();

        var replaceBlendMode = new BlendMode(
            BlendFactors.ONE, 
            BlendFactors.ZERO, 
            BlendFactors.ONE, 
            BlendFactors.ZERO
        );

        var discardBlendMode = new BlendMode(
            BlendFactors.ZERO, 
            BlendFactors.ONE, 
            BlendFactors.ZERO, 
            BlendFactors.ONE
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
                .writes("matLight", solidAux.matLightTexture)
                .writes("shadowFactor", shadowFactor, discardBlendMode);
            
            BlockIdMapping.exportAllIds(builder);
        }

        var wgc = Util.getWorkgroupCountFromSize(screen, 8, 8, 0);

        // do deferred shading in pre-translucent stage
        // no need to flip here because in this case it's sound to read and write to the same image
        var deferredBuilder = pipeline.stage(ProgramStage.PRE_TRANSLUCENT)
            .compute("deferred", "program/object/deferred", "main")
            .overrideObject("targetTexture", mainTextures.overwrite().name())
            .exportFloat("skyCubemapMips", Sky.cubemapMips)
            .exportInt("shadowCascadeCount", Shadow.cascadeCount)
            .exportInt("shadowMapSize", Shadow.size);

        BlockIdMapping.exportAllIds(deferredBuilder);

        deferredBuilder.dispatch2D(wgc.x, wgc.y);

        for (var target : forwardTargets) {
            // albedo should blend normally, but aux data should not blend
            var builder = pipeline.object(target, "program/object/basic", "GbufferShader")
                .exportFloat("skyCubemapMips", Sky.cubemapMips)
                .exportInt("shadowCascadeCount", Shadow.cascadeCount)
                .exportInt("shadowMapSize", Shadow.size)
                .exportBool("forwardLit", true)
                // since the object shader doesn't read from a texture, but just blends into the existing texture,
                // don't use the flipped one for writing
                .writes("color", mainTextures.overwrite())
                .writes("matNormals", solidAux.matNormalsTexture, replaceBlendMode)
                .writes("matPbr", solidAux.matPbrTexture, replaceBlendMode)
                .writes("matLight", solidAux.matLightTexture, replaceBlendMode)
                .writes("shadowFactor", solidAux.matLightTexture, replaceBlendMode);

            BlockIdMapping.exportAllIds(builder);
        }
    }

    public void renderHand(PipelineConfig pipeline, SwapTexture2D mainTextures) {
        var replaceBlendMode = new BlendMode(
            BlendFactors.ONE, 
            BlendFactors.ZERO, 
            BlendFactors.ONE, 
            BlendFactors.ZERO
        );

        ProgramUsage[] handTargets = { ProgramUsage.HAND, ProgramUsage.TRANSLUCENT_HAND };

         for (var target : handTargets) {
            // albedo should blend normally, but aux data should not blend
            var builder = pipeline.object(target, "program/object/basic", "GbufferShader")
                .exportFloat("skyCubemapMips", Sky.cubemapMips)
                .exportInt("shadowCascadeCount", Shadow.cascadeCount)
                .exportInt("shadowMapSize", Shadow.size)
                .exportBool("forwardLit", true)
                // since the object shader doesn't read from a texture, but just blends into the existing texture,
                // don't use the flipped one for writing
                .writes("color", mainTextures.overwrite())
                .writes("matNormals", solidAux.matNormalsTexture, replaceBlendMode)
                .writes("matPbr", solidAux.matPbrTexture, replaceBlendMode)
                .writes("matLight", solidAux.matLightTexture, replaceBlendMode)
                .writes("shadowFactor", solidAux.matLightTexture, replaceBlendMode);

            BlockIdMapping.exportAllIds(builder);
        }
       
    }

}