public module clouds;

import aperture;

import lib.atmosphere;
import lib.util;
import lib.noise;
import lib.math;
import lib.random;

Texture2D cellular2DTexture;

float2 getCloudPlane(float3 viewDir, float altitude) {
    // return viewDir.xz / viewDir.y;
    // float curvature = 1.0 - sqrt(1.0 - min(dot(viewDir.xz, viewDir.xz), 0.999));
    return viewDir.xz / (viewDir.y + 0.05 * dot(viewDir.xz, viewDir.xz));
}

public interface CloudType {
    static const uint selfShadowSteps;

    public float sample(float2 uv);
    public static float altitude();
    public static float density();

    public float2 getTransmittanceAndScattering<T: Rng>(inout Random<T> random, float3 viewDir) {
        if (rayIntersectSphere(getAtmosphereViewingPos(), viewDir, groundRadiusMM) > 0.0) {
            return float2(1.0, 0.0);
        }

        float altitude = this.altitude();
        float density = this.density();

        float windSpeed = 1.0 / altitude;

        float2 plane = getCloudPlane(viewDir, altitude) + windSpeed * ap.timing.timeElapsed;
        // return plane;

        float noise = sample(plane);

        float transmittance = exp(-noise * density);
        float scattering = 1.0;

        if (true || selfShadowSteps > 0) {
            float2 tempPlane = viewDir.xz / viewDir.y;
            float skyLightZenithAngle = 1.0 / abs(getLightVector().y);

            float2 skyLightDirection = normalize(lerp(
                (getSunVector().xz * skyLightZenithAngle - tempPlane),
                (getMoonVector().xz * skyLightZenithAngle - tempPlane),
                float2(linearstep(0.0, 0.2, getMoonVector().y))
            ));

            // skyLightDirection = float2(1.0, 0.0);

            float lightAccumulator = 0.0;
            
            for (uint i = 0; i < selfShadowSteps; i++) {
                plane += skyLightDirection / selfShadowSteps * random.getFloat();
                lightAccumulator += sample(plane) / selfShadowSteps;
            }

            lightAccumulator = max(0.0, lightAccumulator);
            scattering = exp(-lightAccumulator * density * 0.75);
        }

        return float2(transmittance, scattering);
    }
}

public struct CumulusClouds: CloudType {
    static const uint selfShadowSteps = 8;

    public float sample(float2 uv) {
        float timeScale = 0.01;

        float2 gradient;
        float shapeNoise = fbm(SimplexNoise2D(), uv * 0.5, rotationMatrix(radians(15)), 4, 2.0, ap.timing.timeElapsed * timeScale) * 0.5 + 0.5;
        
        float detailNoise = smoothstep(0.0, 1.0, cellular2DTexture.Sample(apt_linearSampler, fract(uv)).r);
        shapeNoise -= 0.1 * detailNoise;

        return smoothstep(0.5, 0.7, shapeNoise);
    }

    public static float altitude() {
        return 512.0;
    }
    
    public static float density() {
        return 5.0;
    }
}

