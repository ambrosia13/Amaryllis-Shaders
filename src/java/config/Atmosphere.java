package config;

import dev.irisshaders.aperture.api.objects.Texture2D;
import dev.irisshaders.aperture.api.objects.TextureFormat;
import dev.irisshaders.aperture.api.pipeline.PipelineConfig;
import dev.irisshaders.aperture.api.pipeline.ProgramStage;

public class Atmosphere {
    public static final int transmittanceLutWidth = 256;
    public static final int transmittanceLutHeight = 128;

    public static final int multiscatteringLutWidth = 32;
    public static final int multiscatteringLutHeight = 32;

    public static final int skyViewWidth = 512;
    public static final int skyViewHeight = 512;

    // max lod minus 0.75, for a nice blend between directional color and uniform brightness
    public static final float skyLutLightSampleLod = (float) Math.floor(
        Math.log((double) Math.min(skyViewWidth, skyViewHeight)) / Math.log(2.0)
    ) - 1.5f;

    // values are kept between 0-1, so we can use 16 bit for extra precision in this range
    public static final TextureFormat transmittanceLutFormat = TextureFormat.RGBA16_UNORM;
    public static final TextureFormat multiscatteringLutFormat = TextureFormat.RGBA16_UNORM;
    
    public static final TextureFormat skyViewTextureFormat = TextureFormat.RG11B10_UFLOAT;

    // populated at startup
    public final Texture2D transmittanceLookupTexture;
    public final Texture2D multiscatteringLookupTexture;

    // written every frame
    public final Texture2D skyViewTexture;

    public Atmosphere(PipelineConfig pipeline) {
        transmittanceLookupTexture = pipeline.texture2D( "transmittanceLookupTexture", transmittanceLutFormat)
            .size(transmittanceLutWidth, transmittanceLutHeight)
            .create();

        multiscatteringLookupTexture = pipeline.texture2D( "multiscatteringLookupTexture", multiscatteringLutFormat)
            .size(multiscatteringLutWidth, multiscatteringLutHeight)
            .create();
        
        skyViewTexture = pipeline.texture2D( "skyViewTexture", skyViewTextureFormat)
            .size(skyViewWidth, skyViewHeight)
            .usesMipmaps() // workaround to get average sky color
            .create();
                
        // workgroup size is 8x8, so divide by texture size to get workgroup count
        // note that texture size is explicitly divisible by 8 to avoid overdraw complications
        pipeline.stage(ProgramStage.SCREEN_SETUP)
            .compute("transmittance", "program/bake/transmittance", "transmittance")
            .exportInt("transmittanceTextureWidth", transmittanceLutWidth)
            .exportInt("transmittanceTextureHeight", transmittanceLutHeight)
            .dispatch2D(transmittanceLutWidth / 8, transmittanceLutHeight / 8);
        
        pipeline.stage(ProgramStage.SCREEN_SETUP)
            .compute("multiscattering", "program/bake/multiscattering", "multiscattering")
            .exportInt("multiscatteringTextureWidth", multiscatteringLutWidth)
            .exportInt("multiscatteringTextureHeight", multiscatteringLutHeight)
            .dispatch2D(multiscatteringLutWidth / 8, multiscatteringLutHeight / 8);
        
        pipeline.stage(ProgramStage.PRE_RENDER) // note that this runs every frame!
            .compute("skyView", "program/sky/skyView", "skyView")
            .exportInt("skyViewWidth", skyViewWidth)
            .exportInt("skyViewHeight", skyViewHeight)
            .dispatch2D(skyViewWidth / 8, skyViewHeight / 8);  
        
        // workaround to get avg sky color
        pipeline.stage(ProgramStage.PRE_RENDER)
            .generateMips(skyViewTexture);
    }
}
