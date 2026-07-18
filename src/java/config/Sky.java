package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.Cubemap;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;

public class Sky {
    public static final TextureFormat skyTextureFormat = TextureFormat.RG11B10_UFLOAT;

    public static final float atmosphereAndCloudsRenderScale = 0.5f;

    // ensure divisible by 8, for compute dispatch, and a power of two, for generating mips
    public static final int cubemapSize = 256;
    public static final int cubemapMips = (int) Math.floor(Math.log((double) cubemapSize) / Math.log(2.0));

    public final Cubemap cubemap;

    public Sky(Screen screen, PipelineConfig pipeline) {
        cubemap = pipeline.cubemap("skyCubemapTexture", skyTextureFormat)
            .size(cubemapSize, cubemapSize)
            .usesMipmaps() // props to my past self for forgetting to put this here and thinking everything was broken
            .create();
        
        pipeline.stage(ProgramStage.PRE_RENDER)
            .compute("skyCubemap", "program/sky/cubemap", "main")
            .exportInt("cubemapSize", cubemapSize)
            .dispatch2D(cubemapSize / 8, cubemapSize / 8);

        pipeline.stage(ProgramStage.PRE_RENDER)
            .generateMips(cubemap);
    }
}
