import org.joml.Vector4f;

import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;

public class TemplatePack implements ShaderPack {
    private static final int CASCADE_COUNT = 4;

    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {
        pipeline.combinationPass("post/combination");

        var mainTexture = pipeline.texture2D("mainTexture", TextureFormat.RGBA8_UNORM)
            .renderSize()
            .create();

        if (pipeline.getSettings().getBoolValue("shadows"))  {
            pipeline.object(ProgramUsage.SHADOW, "object/shadow", "ShadowShader");
        }

        pipeline.object(ProgramUsage.BASIC, "object/basic", "BasicShader")
            .writes("color", mainTexture)
            .exportInt("CASCADE_COUNT", CASCADE_COUNT);
        
        pipeline.object(ProgramUsage.TRANSLUCENT, "object/basic", "BasicShader")
            .writes("color", mainTexture)
            .exportInt("CASCADE_COUNT", CASCADE_COUNT);

        pipeline.stage(ProgramStage.PRE_RENDER).clearToFogColor(mainTexture);
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(40.0f);
        rendererConfig.setShadowCascades(CASCADE_COUNT);
        rendererConfig.setShadowDistance(160.0f);
        rendererConfig.setShadowResolution(1024);
    }

}
