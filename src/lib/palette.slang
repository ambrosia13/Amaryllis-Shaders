/*
    Magic number colors that are used throughout the shader pack. TODO: these should eventually be configurable
*/

module palette;

namespace colors {
    // multiplier of the atmosphere for the night
    public static const float3 NIGHT_COLOR = float3(0.01);

    public static const float3 SUN_COLOR = float3(1.0, 0.85, 0.8);
    public static const float3 MOON_COLOR = float3(1.0, 1.0, 0.9);
}

