package config;

import org.joml.Vector3i;

import dev.irisshaders.aperture.api.objects.Buffer;
import dev.irisshaders.aperture.api.objects.Screen;
import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;
import util.Util;

public class Exposure {
    // Should be a multiple of 64.
    public static final long histogramBins = 256L;

    public static final float minLuminance = 1e-3f;
    public static final float maxLuminance = 2.0f;

    public final Buffer histogram; // containts one uint for each histogram bin
    public final Buffer meteredLuminance; // contains two floats, the current and previous frame luminance

    public Exposure(Screen screen, PipelineConfig pipeline, Texture2D inputTexture) {
        // uint size is 4 bytes, one uint per bin
        histogram = pipeline.buffer("histogram", 4L * histogramBins);

        // float size is 4 bytes, two floats total
        meteredLuminance = pipeline.buffer("meteredLuminance", 4L * 2L);

        var workgroupSize = new Vector3i(8, 8, 1);
        var dimensions = new Vector3i(screen.renderWidth(), screen.renderHeight(), 1);

        var workgroupCounts = Util.getWorkgroupCountFromSize(workgroupSize, dimensions);

        pipeline.stage(ProgramStage.PRE_RENDER)
            .compute("clearHistogram", "program/post/populateHistogram", "clearHistogram")
            .overrideObject("inputTexture", inputTexture.name())
            .exportInt("histogramBins", (int) histogramBins)
            .exportFloat("minLuminance", minLuminance)
            .exportFloat("maxLuminance", maxLuminance)
            .dispatch1D(1);

        pipeline.stage(ProgramStage.POST_RENDER)
            .compute("populateHistogram", "program/post/populateHistogram", "populateHistogram")
            .overrideObject("inputTexture", inputTexture.name())
            .exportInt("histogramBins", (int) histogramBins)
            .exportFloat("minLuminance", minLuminance)
            .exportFloat("maxLuminance", maxLuminance)
            .dispatch2D(workgroupCounts.x, workgroupCounts.y);
    }

}
