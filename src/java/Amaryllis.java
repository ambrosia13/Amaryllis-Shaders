import org.joml.Vector4f;

import config.Gbuffer;
import config.PostPasses;
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
            tex -> tex.renderSize()
        );

        if (pipeline.getSettings().getBoolValue("shadows"))  {
            pipeline.object(ProgramUsage.SHADOW, "object/shadow", "ShadowShader");
        }

        var gbuffer = new Gbuffer(pipeline);
        PostPasses.setup(pipeline, gbuffer, mainTextures);
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(40.0f);
        rendererConfig.setShadowCascades(CASCADE_COUNT);
        rendererConfig.setShadowDistance(160.0f);
        rendererConfig.setShadowResolution(1024);
    }

}
