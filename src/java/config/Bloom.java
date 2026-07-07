package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;

public class Bloom {
    public static final TextureFormat bloomTextureFormat = TextureFormat.RG11B10_UFLOAT;

    public final Texture2D downsampleTexture;
    public final Texture2D upsampleTexture;

    public Bloom(Screen screen, PipelineConfig pipeline, Texture2D inputTexture, Texture2D outputTexture) {
        downsampleTexture = pipeline.texture2D("bloomDownsampleTexture", bloomTextureFormat)
            .usesMipmaps()
            .size(screen.renderWidth() / 2, screen.renderHeight() / 2) // half the size of the screen to start with
            .create();

        upsampleTexture = pipeline.texture2D("bloomUpsampleTexture", bloomTextureFormat)
            .usesMipmaps()
            .size(screen.renderWidth() / 2, screen.renderHeight() / 2) // half the size of the screen to start with
            .create();

        // first downsample: reads from inputTexture, writes to downsampleTexture lod 0 (logical lod 1)
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("bloomDownsampleFirst", "program/bloom/downsample", "downsampleFirst")
            .exportInt("lod", 1)
            .overrideObject("inputTexture", inputTexture.name())
            .writes("color", downsampleTexture, 0);

        int minDimension = Math.min(screen.renderWidth(), screen.renderHeight());

        // subtract 1 here because the first pass was the blit from the input texture to the base lod of the downsample texture
        int numBloomPasses = (int) Math.floor(Math.log((double) minDimension) / Math.log(2.0)) - 1;

        for (int i = 1; i <= numBloomPasses; i++) {
            pipeline.stage(ProgramStage.POST_RENDER)
                .composite("bloomDownsample" + i, "program/bloom/downsample", "downsample")
                .exportInt("lod", i)
                .overrideObject("inputTexture", downsampleTexture.name())
                .writes("color", downsampleTexture, i);
        }

        // first upsample: reads from bloomDownsampleTexture highest mip and writes to bloomUpsampleTexture highest mip
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("bloomUpsampleFirst", "program/bloom/upsample", "upsampleFirst")
            .exportInt("lod", numBloomPasses)
            .exportInt("mipCount", numBloomPasses + 1)
            .writes("color", upsampleTexture, numBloomPasses);
            

        // the order of upsampling is highest lod to lowest lod
        for (int i = numBloomPasses - 1; i >= 0; i--) {
            pipeline.stage(ProgramStage.POST_RENDER)
                .composite("bloomUpsample" + i, "program/bloom/upsample", "upsample")
                .exportInt("lod", i)
                .exportInt("mipCount", numBloomPasses + 1)
                .writes("color", upsampleTexture, i);
        }

        // finally, the merge pass
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("bloomMerge", "program/bloom/merge", "main")
            .overrideObject("inputTexture", inputTexture.name())
            .writes("color", outputTexture);
    }
}
