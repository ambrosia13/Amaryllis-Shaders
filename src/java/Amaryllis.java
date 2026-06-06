import org.joml.Vector4f;

import config.Gbuffer;
import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;
import util.SwapTexture2D;

public class Amaryllis implements ShaderPack {
    private static final int CASCADE_COUNT = 4;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {
        // the main texture, written to after the gbuffer outputs are resolved and used for the combination pass
        var mainTextures = new SwapTexture2D(
            pipeline, 
            "mainTexture", 
            TextureFormat.RG11B10_SFLOAT, 
            (tex) -> tex.renderSize()
        );

        var gbuffer = new Gbuffer(pipeline);

        if (pipeline.getSettings().getBoolValue("shadows"))  {
            pipeline.object(ProgramUsage.SHADOW, "object/shadow", "ShadowShader");
        }

        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("deferred", "post/deferred", "main")
            .writes("color", mainTextures.firstWrite());
            // .overrideObject("in_albedoTexture", gbuffer.solidOutputs.albedoTexture.name())
            // .overrideObject("in_matNormalsTexture", gbuffer.solidOutputs.matNormalsTexture.name())
            // .overrideObject("in_matPbrTexture", gbuffer.solidOutputs.matPbrTexture.name())
            // .overrideObject("in_matLightTexture", gbuffer.solidOutputs.matLightTexture.name());

        pipeline.combinationPass("post/combination");
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(40.0f);
        rendererConfig.setShadowCascades(CASCADE_COUNT);
        rendererConfig.setShadowDistance(160.0f);
        rendererConfig.setShadowResolution(1024);
    }

}
