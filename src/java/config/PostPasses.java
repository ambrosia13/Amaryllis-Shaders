package config;

import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.SwapTexture2D;

public class PostPasses {
    public static void setup(PipelineConfig pipeline, Gbuffer gbuffer, SwapTexture2D mainTextures) {
        // we don't need to do a flip for the first write, since it reads from elsewhere and writes to _a.
        // after this, we still use the default behavior of reading from _a and writing to _b, and only then
        // do we swap so that _b is only read from after it's written to.
        deferred(pipeline, mainTextures.firstWrite());

        // no flip needed here!
        var sort = new Sort(pipeline, mainTextures.read(), mainTextures.write());

        mainTextures.flip();

        // combination pass has no outputs
        pipeline.combinationPass("post/combination");
    }

    static void deferred(PipelineConfig pipeline, Texture2D output) {
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("deferred", "post/deferred", "main")
            .writes("color", output);
    }
}
