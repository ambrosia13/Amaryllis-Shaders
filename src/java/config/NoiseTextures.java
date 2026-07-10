package config;

import dev.irisshaders.aperture.api.pipeline.PipelineConfig;

public class NoiseTextures {
    public static void load(PipelineConfig pipeline) {
        pipeline.loadPNGTexture("cellular2DTexture", "textures/cellular2DTexture.png");
    }
}
