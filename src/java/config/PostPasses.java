package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.SwapTexture2D;

public class PostPasses {
    public static void setup(Screen screen, PipelineConfig pipeline, Atmosphere atmosphere, Gbuffer gbuffer, SwapTexture2D mainTextures) {
        // run the exposure metering near the end of teh pipeline
        // the exposure pass doesn't modify the image; just calculates its exposure, so no need to flip here
        var exposure = new Exposure(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        var bloom = new Bloom(screen, pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        // combination pass has no explicit outputs and reads from the ping pong
        pipeline.combinationPass("program/post/combination")
            .overrideObject("outputTexture", mainTextures.read().name());
    }
}
