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

    float3 nightContribution = Brightnesses.NIGHT_SKY_BRIGHTNESS * Colors.NIGHT_COLOR * raymarchScattering(
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
    float lod
) {
    return Brightnesses.ATMOSPHERE_BRIGHTNESS * (getValFromSkyLUT(skyLutDay, viewDir, getSunVector(), lod) +
        Brightnesses.NIGHT_SKY_BRIGHTNESS * Colors.NIGHT_COLOR * getValFromSkyLUT(skyLutNight, viewDir, getMoonVector(), lod));
}

void drawSunOnAtmosphere(inout float3 atmosphere, Texture2D transmittanceLut, float3 viewDir) {
    float3 viewPos = getAtmosphereViewingPos();

    float3 sunVector = getSunVector();
    float3 moonVector = -sunVector;

    float3 transmittance = getValFromTLUT(transmittanceLut, viewPos, viewDir);

    float sunAngularRadiusLowerBound = radians(1.0);
    float sunAngularRadiusUpperBound = radians(0.5);

    float moonAngularRadiusLowerBound = radians(1.5);
    float moonAngularRadiusUpperBound = radians(1.0);

    float sunDisk = smoothstep(cos(sunAngularRadiusLowerBound), cos(sunAngularRadiusUpperBound), dot(viewDir, sunVector));
    float moonDisk = smoothstep(cos(moonAngularRadiusLowerBound), cos(moonAngularRadiusUpperBound), dot(viewDir, moonVector));

    atmosphere += Brightnesses.SUN_BRIGHTNESS * sunDisk * Colors.SUN_COLOR * transmittance;
    atmosphere += Brightnesses.MOON_BRIGHTNESS * moonDisk * Colors.MOON_COLOR * transmittance;
}
