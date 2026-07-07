package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;

public class Bloom {
    public static final TextureFormat bloomTextureFormat = TextureFormat.RG11B10_SFLOAT;

    public final Texture2D downsampleTexture;
    public final Texture2D upsampleTexture;

    public Bloom(Screen screen, PipelineConfig pipeline, Texture2D inputTexture) {
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
            .composite("bloomDownsampleFirst", "program/downsample.slang", "main")
            .exportInt("lod", 1)
            .overrideObject("inputTexture", inputTexture.name())
            .writes("color", downsampleTexture, 0);
    }
}
