/*
    Some code from this file is taken and/or referenced from "Production Sky Rendering" at https://www.shadertoy.com/view/slSXRW,
    which is an implementation of "A Scalable and Production Ready Sky and Atmosphere Rendering Technique", Hillaire (2020).

    Minimal code changes; modified for my use case. The original shadertoy code was released under the MIT License.
*/

import lib.atmosphere;
import lib.palette;
import lib.math;
import lib.util;

extern static const uint skyViewWidth; 
extern static const uint skyViewHeight; 

Texture2D transmittanceLookupTexture;
Texture2D multiscatteringLookupTexture;

RWTexture2D<float4> skyViewTexture;

// number of steps to use for sky view
static const int numScatteringSteps = 32;

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void skyView(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(skyViewWidth, skyViewHeight);

    float clipV = uv.y * 2.0 - 1.0;

    float azimuthAngle = (uv.x - 0.5) * 2.0 * PI;
    // Non-linear mapping of altitude. See Section 5.3 of the paper.
    float adjV;
    if (uv.y < 0.5) {
        float coord = -clipV;
        adjV = -coord * coord;
    } else {
        float coord = clipV;
        adjV = coord * coord;
    }

    float3 skyViewPos = getAtmosphereViewingPos();

    float height = length(skyViewPos);
    float3 up = skyViewPos / height;
    float horizonAngle = acos(clamp(sqrt(height * height - groundRadiusMM * groundRadiusMM) / height, -1.0, 1.0)) - 0.5 * PI;
    float altitudeAngle = adjV * 0.5 * PI - horizonAngle;

    float cosAltitude = cos(altitudeAngle);
    float3 rayDir = float3(cosAltitude * sin(azimuthAngle), sin(altitudeAngle), -cosAltitude * cos(azimuthAngle));

    float sunAltitude = (0.5 * PI) - acos(dot(getSunVector(), up));
    float3 sunDir = float3(0.0, sin(sunAltitude), -cos(sunAltitude));

    // float moonAltitude = (0.5 * PI) - acos(dot(getMoonVector(), up));
    // float3 moonDir = float3(0.0, sin(moonAltitude), -cos(moonAltitude));
    float3 moonDir = -sunDir; // doing it this way allows the day and night sky to live on the same texture!!

    float atmoDist = rayIntersectSphere(skyViewPos, rayDir, atmosphereRadiusMM);
    float groundDist = rayIntersectSphere(skyViewPos, rayDir, groundRadiusMM);

    float tMax = select(groundDist < 0.0, atmoDist, groundDist);

    float3 transmittance; //ignored
    float3 dayColor = raymarchScattering(
        transmittanceLookupTexture, 
        multiscatteringLookupTexture, 
        skyViewPos, 
        rayDir, 
        sunDir, 
        Colors.SUN_COLOR, 
        1.0,
        tMax, 
        float(numScatteringSteps),
        transmittance
    );

    float3 nightColor = raymarchScattering(
        transmittanceLookupTexture, 
        multiscatteringLookupTexture, 
        skyViewPos, 
        rayDir, 
        moonDir, 
        Colors.MOON_COLOR, 
        1.0,
        tMax, 
        float(numScatteringSteps),
        transmittance
    );

    float3 skyColor = Brightnesses.ATMOSPHERE_BRIGHTNESS * (
        dayColor + Brightnesses.NIGHT_SKY_BRIGHTNESS * Colors.NIGHT_COLOR * nightColor
    );

    skyViewTexture.Store(globalInvocationId.xy, float4(skyColor, 1.0));
}
