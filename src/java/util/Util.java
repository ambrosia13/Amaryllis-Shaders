package util;

import org.joml.Vector2i;
import org.joml.Vector3i;

import dev.irisshaders.aperture.api.objects.Screen;

public class Util {
    public static Vector3i getWorkgroupCountFromSize(Vector3i workgroupSize, Vector3i dimensions) {
        var rounded = (dimensions.add(workgroupSize).sub(new Vector3i(1)));
        rounded.x /= workgroupSize.x;
        rounded.y /= workgroupSize.y;
        rounded.z /= workgroupSize.z;

        return rounded;
    }

    public static Vector2i getWorkgroupCountFromSize(Screen screen, int sizeX, int sizeY, int lod) {
        var roundedX = Math.ceilDiv(screen.renderWidth(), 1 << lod) + sizeX - 1;
        var roundedY = Math.ceilDiv(screen.renderHeight(), 1 << lod) + sizeY - 1;

        roundedX /= sizeX;
        roundedY /= sizeY;

        return new Vector2i(roundedX, roundedY);
    }
}
