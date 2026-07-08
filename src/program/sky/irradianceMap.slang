import lib.atmosphere;
import lib.palette;
import lib.math;
import lib.util;
import lib.random;
import lib.sky;

extern static const uint skyIrradianceMapWidth; 
extern static const uint skyIrradianceMapHeight; 
extern static const uint skyIrradianceSamples;

Texture2D skyViewDayTexture;
Texture2D skyViewNightTexture;

RWTexture2D<float4> skyIrradianceTexture;

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void main(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(skyIrradianceMapWidth, skyIrradianceMapHeight);

    // Same parameterization as the sky view. See skyView.slang.
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

    float3 irradiance = float3(0.0);

    Random random = Random(globalInvocationId.x + globalInvocationId.y * skyIrradianceMapWidth);

    for (uint i = 0; i < skyIrradianceSamples; i++) {
        float3 sampleDir = random.getCosineVector(rayDir);
        irradiance += PI * sampleAtmosphere(skyViewDayTexture, skyViewNightTexture, sampleDir, 0.0) / skyIrradianceSamples;
    }

    // irradiance = sampleAtmosphere(skyViewDayTexture, skyViewNightTexture, rayDir, 0.0);

    skyIrradianceTexture.Store(globalInvocationId.xy, float4(irradiance, 1.0));
}
