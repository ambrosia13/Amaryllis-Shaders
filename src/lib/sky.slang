public module sky;

import lib.atmosphere;
import lib.palette;
import lib.util;
import lib.clouds;

// for when the sky view LUTs aren't enough, like when you're outside the atmosphere looking inwards, or for fog
public float3 raymarchAtmosphere(
    Texture2D transmittanceLut,
    Texture2D multiscatteringLut,
    float3 rayPos,
    float3 rayDir,
    float mieAmount,
    float tMax,
    int numSteps,
    out float3 transmittance
) {
    float atmoDist = rayIntersectSphere(rayPos, rayDir, atmosphereRadiusMM);
    float groundDist = rayIntersectSphere(rayPos, rayDir, groundRadiusMM);

    // transform world units to atmosphere units
    tMax = min(tMax, atmoDist);

    float3 dayContribution = raymarchScattering(
        transmittanceLut, 
        multiscatteringLut, 
        rayPos, 
        rayDir, 
        getSunVector(), 
        Colors.SUN_COLOR, 
        mieAmount, 
        tMax, 
        numSteps,
        transmittance,
    );

    float3 nightContribution = Brightnesses.NIGHT_SKY_BRIGHTNESS * Colors.NIGHT_COLOR * raymarchScattering(
        transmittanceLut, 
        multiscatteringLut,
        rayPos, 
        rayDir, 
        getMoonVector(), 
        Colors.MOON_COLOR, 
        mieAmount, 
        tMax, 
        numSteps,
        transmittance
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

void drawCloudsOnAtmosphere<T: CloudType>(
    inout float3 atmosphere, 
    Texture2D transmittanceLut, 
    Texture2D skyLut, 
    float3 viewDir,
    float2 cloudsTransmittanceAndScattering,
) {
    float3 skyViewPos = getAtmosphereViewingPos();

    float3 sunVector = getSunVector();
    float3 moonVector = getMoonVector();

    float3 cloudPos = float3(0.0, skyViewPos.y + T.altitude() * 1e-6, 0.0);

    float3 sunTransmittance = getValFromTLUT(transmittanceLut, cloudPos, sunVector);
    float3 moonTransmittance = getValFromTLUT(transmittanceLut, cloudPos, moonVector);

    float3 scatteringColor = 
        Brightnesses.SUNLIGHT_BRIGHTNESS * Colors.SUN_COLOR * sunTransmittance + 
        Brightnesses.NIGHT_SKY_BRIGHTNESS * Brightnesses.MOONLIGHT_BRIGHTNESS * Colors.MOON_COLOR * moonTransmittance;
    
    float3 ambientCloudColor = getValFromSkyLUT(skyLut, float3(1.0), getSunVector());

    float3 cloudScattering = cloudsTransmittanceAndScattering.y * scatteringColor
        * (1.0 + (getMiePhase(dot(viewDir, sunVector), 0.7) + getMiePhase(dot(viewDir, moonVector), 0.7)))
        + ambientCloudColor;
    
    float3 cloudyAtmosphere = lerp(cloudScattering, atmosphere, cloudsTransmittanceAndScattering.x);

    atmosphere = lerp(atmosphere, cloudyAtmosphere, smoothstep(0.0, 0.1, viewDir.y));
}
