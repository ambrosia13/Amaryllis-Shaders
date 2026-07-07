/*
    Magic number colors that are used throughout the shader pack. TODO: these should eventually be configurable
*/

module palette;

import lib.color;

namespace Colors {
    // the color multiplier of the overall night sky
    public static const float3 NIGHT_COLOR = float3(0.8, 0.95, 1.0);

    public static const float3 SUN_COLOR = float3(1.0, 0.85, 0.8);
    public static const float3 MOON_COLOR = float3(1.0, 1.0, 0.9);
}

namespace Brightnesses {
    // the ratio of the visible sky to the scene's direct lighting; also affects ambient sky lighting
    public static const float ATMOSPHERE_BRIGHTNESS = 1.0;

    // the ratio of the day sky to the night sky
    public static const float NIGHT_SKY_BRIGHTNESS = 0.02;

    public static const float SUNLIGHT_BRIGHTNESS = 1.0;
    public static const float MOONLIGHT_BRIGHTNESS = 0.005;

    public static const float SUN_BRIGHTNESS = 1000.0;
    public static const float MOON_BRIGHTNESS = 1.0;

    public static const float AMBIENT_SKYLIGHT_BRIGHTNESS = 2.0;
    public static const float BLOCKLIGHT_BRIGHTNESS = 0.1;
    public static const float CAVE_BRIGHTNESS = 0.002;

    // public static const float AMBIENT_LIGHT_BRIGHTNESS = 0.5;
}
