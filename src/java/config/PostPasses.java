package config;

import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.SwapTexture2D;

public class PostPasses {
    public static void setup(PipelineConfig pipeline, Atmosphere atmosphere, Gbuffer gbuffer, SwapTexture2D mainTextures) {
        // combination pass has no explicit outputs and reads from the ping pong
        pipeline.combinationPass("program/post/combination")
            .overrideObject("outputTexture", mainTextures.read().name());
    }
}
