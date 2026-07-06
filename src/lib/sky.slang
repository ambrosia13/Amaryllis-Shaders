public module sky;

import lib.atmosphere;
import lib.palette;
import lib.util;

// for when the sky view LUTs aren't enough, like when you're outside the atmosphere looking inwards
public float3 raymarchAtmosphere(
    Texture2D transmittanceLut,
    Texture2D multiscatteringLut,
    float3 rayPos,
    float3 rayDir
) {
    float atmoDist = rayIntersectSphere(rayPos, rayDir, atmosphereRadiusMM);
    float groundDist = rayIntersectSphere(rayPos, rayDir, groundRadiusMM);

    float tMax = select(groundDist < 0.0, atmoDist, groundDist);

    float3 dayContribution = raymarchScattering(
        transmittanceLut, 
        multiscatteringLut, 
        rayPos, 
        rayDir, 
        getSunVector(), 
        Colors.SUN_COLOR, 
        1.0, 
        tMax, 
        float(numScatteringSteps)
    );

    float3 nightContribution = Brightnesses.NIGHT_BRIGHTNESS * Colors.NIGHT_COLOR * raymarchScattering(
        transmittanceLut, 
        multiscatteringLut,
        rayPos, 
        rayDir, 
        getMoonVector(), 
        Colors.MOON_COLOR, 
        1.0, 
        tMax, 
        float(numScatteringSteps)
    );

    return Brightnesses.ATMOSPHERE_BRIGHTNESS * (dayContribution + nightContribution);
}

float3 sampleAtmosphere(
    Texture2D skyLutDay, 
    Texture2D skyLutNight,
    float3 viewDir,
) {
    return Brightnesses.ATMOSPHERE_BRIGHTNESS * (getValFromSkyLUT(skyLutDay, viewDir, getSunVector()) +
        Brightnesses.NIGHT_BRIGHTNESS * Colors.NIGHT_COLOR * getValFromSkyLUT(skyLutNight, viewDir, getMoonVector()));
}
