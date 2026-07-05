import org.joml.Vector4f;

import config.Atmosphere;
import config.Gbuffer;
import config.PostPasses;
import config.Shadow;
import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;
import util.SwapTexture2D;

public class Amaryllis implements ShaderPack {
    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {
        // the main texture, written to after the gbuffer outputs are resolved and used for the combination pass
        var mainTextures = new SwapTexture2D(
            pipeline, 
            "mainTexture", 
            TextureFormat.RGBA16_SFLOAT, 
            tex -> tex.renderSize()
        );

        Shadow.setup(pipeline);
        var atmosphere = new Atmosphere(pipeline);
        var gbuffer = new Gbuffer(pipeline, mainTextures);
        PostPasses.setup(pipeline, gbuffer, mainTextures);
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(40.0f);
        rendererConfig.setShadowCascades(Shadow.CASCADE_COUNT);
        rendererConfig.setShadowDistance(160.0f);
        rendererConfig.setShadowResolution(1024);
    }

}
