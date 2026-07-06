package util;

import org.joml.Vector3i;

public class Util {
    public static Vector3i getWorkgroupCountFromSize(Vector3i workgroupSize, Vector3i dimensions) {
        var rounded = (dimensions.add(workgroupSize).sub(new Vector3i(1)));
        rounded.x /= workgroupSize.x;
        rounded.y /= workgroupSize.y;
        rounded.z /= workgroupSize.z;

        return rounded;
    }
}
