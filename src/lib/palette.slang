/*
    Magic number colors that are used throughout the shader pack. TODO: these should eventually be configurable
*/

module palette;

namespace Colors {
    // the color multiplier of the overall night sky
    public static const float3 NIGHT_COLOR = float3(1.0);

    public static const float3 SUN_COLOR = float3(1.0, 0.85, 0.8);
    public static const float3 MOON_COLOR = float3(1.0, 1.0, 0.9);
}

namespace Brightnesses {
    // the ratio of day brightness to night brightness
    public static const float NIGHT_BRIGHTNESS = 0.01;

    public static const float ATMOSPHERE_BRIGHTNESS = 7.5;
}
