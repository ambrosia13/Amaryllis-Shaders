import config.Atmosphere;
import config.Gbuffer;
import config.NoiseTextures;
import config.PostPasses;
import config.Shadow;
import config.Sky;
import dev.irisshaders.aperture.api.*;
import dev.irisshaders.aperture.api.objects.*;
import dev.irisshaders.aperture.api.pipeline.*;
import dev.irisshaders.aperture.api.renderer.*;
import mapping.BlockIdMapping;
import util.SwapTexture2D;

public class Amaryllis implements ShaderPack {
    @Override
    public void configurePipeline(Screen screen, PipelineConfig pipeline) {
        // the main texture, written to after the gbuffer outputs are resolved and used for the combination pass
        var mainTextures = new SwapTexture2D(
            pipeline, 
            "mainTexture", 
            TextureFormat.RGBA16_SFLOAT, 
            tex -> tex.renderSize()
        );

        NoiseTextures.load(pipeline);

        var sky = new Sky(screen, pipeline);
        Shadow.setup(pipeline);
        var atmosphere = new Atmosphere(pipeline);
        var gbuffer = new Gbuffer(pipeline, mainTextures);
        PostPasses.setup(screen, pipeline, atmosphere, gbuffer, mainTextures);
    }

    @Override
    public void configureRenderer(RendererConfig rendererConfig) {
        rendererConfig.setSunPathRotation(40.0f);
        rendererConfig.setShadowCascades(Shadow.cascadeCount);
        rendererConfig.setShadowDistance(160.0f);
        rendererConfig.setShadowResolution(Shadow.size);
    }

    @Override
    public int setBlockId(IBlockState block) {
        if (block.hasTag("minecraft:leaves")) {
            return BlockIdMapping.FOLIAGE_ID;
        }

        if (block.getBlockId().toString().equals("minecraft:water")) {
            return BlockIdMapping.WATER_ID;
        }

        if (
            block.getBlockId().toString().equals("minecraft:sugar_cane") || 
            block.getBlockId().toString().equals("minecraft:kelp_plant") || 
            block.hasTag("minecraft:crops") || 
            block.hasTag("minecraft:flowers") || 
            block.hasTag("minecraft:replaceable_by_trees")
        ) {
            return BlockIdMapping.SURFACE_FOLIAGE_ID;
        }

        return 0;
    }
}
