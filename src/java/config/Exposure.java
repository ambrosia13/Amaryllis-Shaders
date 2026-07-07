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

    public static final float minLuminance = 0.000001f; // the min luminance we will account for, selected by choosing an appropriate midnight brightness
    public static final float maxLuminance = 2.0f;

    // Units are in EV
    public static final float minEV100 = 8.0f;
    public static final float maxEV100 = -1.0f;

    public final Buffer histogram; // containts one uint for each histogram bin
    public final Buffer meteredLuminance; // contains a float for the metered luminance

    public Exposure(Screen screen, PipelineConfig pipeline, Texture2D inputTexture, Texture2D outputTexture) {
        // uint size is 4 bytes, one uint per bin
        histogram = pipeline.buffer("histogram", 4L * histogramBins);

        // float size is 4 bytes
        meteredLuminance = pipeline.buffer("meteredLuminance", 4L);

        var workgroupSize = new Vector3i(8, 8, 1);
        var dimensions = new Vector3i(screen.renderWidth(), screen.renderHeight(), 1);

        var workgroupCounts = Util.getWorkgroupCountFromSize(workgroupSize, dimensions);

        pipeline.stage(ProgramStage.PRE_RENDER)
            .compute("clearHistogram", "program/post/exposure/populateHistogram", "clearHistogram")
            .overrideObject("inputTexture", inputTexture.name())
            .exportInt("histogramBins", (int) histogramBins)
            .exportFloat("minLuminance", minLuminance)
            .exportFloat("maxLuminance", maxLuminance)
            .dispatch1D(1);

        pipeline.stage(ProgramStage.POST_RENDER)
            .compute("populateHistogram", "program/post/exposure/populateHistogram", "populateHistogram")
            .overrideObject("inputTexture", inputTexture.name())
            .exportInt("histogramBins", (int) histogramBins)
            .exportFloat("minLuminance", minLuminance)
            .exportFloat("maxLuminance", maxLuminance)
            .dispatch2D(workgroupCounts.x, workgroupCounts.y);
        
        pipeline.stage(ProgramStage.POST_RENDER)
            .compute("resolveLuminance", "program/post/exposure/resolveLuminance", "percentileLuminance")
            .exportInt("histogramBins", (int) histogramBins)
            .exportFloat("minLuminance", minLuminance)
            .exportFloat("maxLuminance", maxLuminance)
            .dispatch1D(1);
        
        // temporary measure until we can piggyback off a different pass (like taa)
        pipeline.stage(ProgramStage.POST_RENDER)
            .composite("applyExposure", "program/post/exposure/apply", "main")
            .exportFloat("minEV100", minEV100)
            .exportFloat("maxEV100", maxEV100)
            .overrideObject("inputTexture", inputTexture.name())
            .writes("color", outputTexture);
    }

}
