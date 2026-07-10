package util;

import java.util.function.Consumer;

import dev.irisshaders.aperture.api.objects.Texture3D;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.objects.UnbuiltTexture3D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;

public class SwapTexture3D {
    private boolean flipped;

    public final Texture3D a;
    public final Texture3D b;

    public SwapTexture3D(PipelineConfig pipeline, String name, TextureFormat format, Consumer<UnbuiltTexture3D> config) {
        var unbuiltA = pipeline.texture3D(name + "_a", format);
        var unbuiltB = pipeline.texture3D(name + "_b", format);

        config.accept(unbuiltA);
        config.accept(unbuiltB);

        a = unbuiltA.create();
        b = unbuiltB.create();

        flipped = false;
    }

    public void flip() {
        flipped = !flipped;
    }

    public Texture3D read() {
        return flipped ? b : a;
    }

    // the first write outputs to the main texture
    public Texture3D overwrite() {
        return read();
    }

    public Texture3D write() {
        return flipped ? a : b;
    }

}
