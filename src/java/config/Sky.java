package config;

import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;

public class Sky {
    public static final TextureFormat skyTextureFormat = TextureFormat.RG11B10_UFLOAT;

    public static final int cubemapSize = 512;
    public static final float atmosphereAndCloudsRenderScale = 0.5f;

    // public final Texture3D cubemap;



    public Sky(Screen screen, PipelineConfig pipeline) {
        // cubemap = pipeline.texture3D("cubemap", skyTextureFormat)
        //     .size(cubemapSize, cubemapSize, 6)
        //     .create();
    }
}
