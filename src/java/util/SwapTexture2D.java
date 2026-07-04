package util;

import java.util.function.Consumer;

import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;

public class SwapTexture2D {
    private boolean flipped;

    public final Texture2D a;
    public final Texture2D b;

    public SwapTexture2D(PipelineConfig pipeline, String name, TextureFormat format, Consumer<UnbuiltTexture2D> config) {
        var unbuiltA = pipeline.texture2D(name + "_a", format);
        var unbuiltB = pipeline.texture2D(name + "_b", format);

        config.accept(unbuiltA);
        config.accept(unbuiltB);

        a = unbuiltA.create();
        b = unbuiltB.create();

        flipped = false;
    }

    public void flip() {
        flipped = !flipped;
    }

    public Texture2D read() {
        return flipped ? b : a;
    }

    // the first write outputs to the main texture
    public Texture2D overwrite() {
        return read();
    }

    public Texture2D write() {
        return flipped ? a : b;
    }
}
