package config;

import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramUsage;

public class Shadow {
    public static final int CASCADE_COUNT = 4;

    public static void setup(PipelineConfig pipeline) {
        if (pipeline.getSettings().getBoolValue("shadows"))  {
            pipeline.object(ProgramUsage.SHADOW, "program/object/shadow", "ShadowShader");
        }
    }
}
