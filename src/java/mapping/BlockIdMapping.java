package mapping;

import dev.irisshaders.aperture.api.commands.CompositeCommand;
import dev.irisshaders.aperture.api.objects.ObjectShaderBuilder;

public class BlockIdMapping {
    public static final int WATER_ID = 1;
    public static final int FOLIAGE_ID = 2;
    public static final int SURFACE_FOLIAGE_ID = 3; // foliage that is on a surface, e.g. tall grass, flowers

    public static void exportAllIds(ObjectShaderBuilder builder) {
        builder.exportInt("WATER_ID", WATER_ID);
        builder.exportInt("FOLIAGE_ID", FOLIAGE_ID);
        builder.exportInt("SURFACE_FOLIAGE_ID", SURFACE_FOLIAGE_ID);
    }
    
    public static void exportAllIds(CompositeCommand builder) {
        builder.exportInt("WATER_ID", WATER_ID);
        builder.exportInt("FOLIAGE_ID", FOLIAGE_ID);
        builder.exportInt("SURFACE_FOLIAGE_ID", SURFACE_FOLIAGE_ID);
    }
}