package config;

import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.*;

public class Sort {
    public final Gbuffer.OutputsAux compositeAux;

    public Sort(PipelineConfig pipeline, Texture2D inputTexture, Texture2D outputTexture) {
        // since this is written to in a post pass, we don't need it to be cleared
        compositeAux = new Gbuffer.OutputsAux("composite", pipeline, false);

        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("sort", "post/sort", "main")
            .writes("color", outputTexture)
            .writes("matNormals", compositeAux.matNormalsTexture)
            .writes("matPbr", compositeAux.matPbrTexture)
            .writes("matLight", compositeAux.matLightTexture);
    }
}
