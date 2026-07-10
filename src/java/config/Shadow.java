package config;

import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramUsage;

public class Shadow {
    public static final int cascadeCount = 4;
    public static final int size = 1024;

    public static void setup(PipelineConfig pipeline) {
        if (pipeline.settings().getBoolValue("shadows"))  {
            pipeline.object(ProgramUsage.SHADOW, "program/object/shadow", "ShadowShader");
        }
    }
}
