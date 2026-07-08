package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.SwapTexture2D;

public class PostPasses {
    public static void setup(Screen screen, PipelineConfig pipeline, Atmosphere atmosphere, Gbuffer gbuffer, SwapTexture2D mainTextures) {
        // effect pass - for things like reflections and fog
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("effect", "program/post/effect", "main")
            .overrideObject("inputTexture", mainTextures.read().name())
            .writes("color", mainTextures.write());
        
        mainTextures.flip();;

        // run the exposure metering near the end of teh pipeline
        var exposure = new Exposure(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        var bloom = new Bloom(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        // combination pass has no explicit outputs and reads from the ping pong
        pipeline.combinationPass("program/post/combination")
            .overrideObject("outputTexture", mainTextures.read().name());
    }
}
