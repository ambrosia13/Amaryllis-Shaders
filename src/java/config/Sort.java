package config;

import dev.irisshaders.aperture.api.pipeline.*;

public class Sort {
    public final Gbuffer.OutputsAux compositeAux;

    public Sort(PipelineConfig pipeline) {
        // since this is written to in a post pass, we don't need it to be cleared
        compositeAux = new Gbuffer.OutputsAux("composite", pipeline, false);
    }
}
