package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.SwapTexture2D;
import util.Util;

public class PostPasses {
    public static final int hiDepthMaxLevels = 5; // 0, 2, 4, 6, 8
    public static final int hiLevelStep = 1; // see hi-z compute shader for details

    public static void setup(Screen screen, PipelineConfig pipeline, Atmosphere atmosphere, Gbuffer gbuffer, SwapTexture2D mainTextures) {
        int hiDepthLevels = hiZPass(screen, pipeline);

        // effect pass - for things like reflections and fog
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("effect", "program/post/effect", "main")
            .overrideObject("inputTexture", mainTextures.read().name())
            .writes("color", mainTextures.write());
        
        mainTextures.flip();

        // run the exposure metering near the end of teh pipeline
        var exposure = new Exposure(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        var bloom = new Bloom(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        // combination pass has no explicit outputs and reads from the ping pong
        pipeline.combinationPass("program/post/combination")
            .overrideObject("outputTexture", mainTextures.read().name());
    }

    // returns count of depth levels
    static int hiZPass(Screen screen, PipelineConfig pipeline) {
        // hi-z downsampling pass; downsamples the depth texture in a compute shader (not single-pass)
        var hiDepthTexture = pipeline.texture2D("hiDepthTexture", TextureFormat.R32_SFLOAT)
            .renderSize()
            .usesMipmaps()
            .create();
        
        var wgc = Util.getWorkgroupCountFromSize(screen, 8, 8, 0);

        pipeline.stage(ProgramStage.POST_RENDER)
            .compute("copyFirstDepth", "program/hiZ", "copyFirstDepth")
            .dispatch2D(wgc.x, wgc.y);

        int minDimension = Math.min(screen.renderWidth(), screen.renderHeight());
        int maxDownsampleLevel = (int) Math.floor(Math.log((double) minDimension) / Math.log(2.0));

        int i;

        for (i = hiLevelStep; i < hiDepthMaxLevels; i++) {
            int level = i * hiLevelStep;

            if (level > maxDownsampleLevel) break;

            wgc = Util.getWorkgroupCountFromSize(screen, 8, 8, level);

            pipeline.stage(ProgramStage.POST_RENDER)
                .compute("depthDownsample" + level, "program/hiZ", "depthDownsample")
                .exportInt("srcLod", level - hiLevelStep)
                .exportInt("dstLod", level)
                .dispatch2D(wgc.x, wgc.y);
        }

        return i;
    }
}
