import aperture;

import lib.atmosphere;
import lib.clouds;
import lib.palette;
import lib.math;
import lib.util;

extern static const uint cubemapSize; 

RWTexture2DArray skyCubemapTexture;
Texture2D<float4> skyViewTexture;

void getCubemapViewDirs(float2 uv, out float3 viewDirs[6]) {
    float3 a = normalize(float3(uv - 0.5, 0.5));

    viewDirs[0] = float3(a.z, -a.y, -a.x);
    viewDirs[1] = float3(-a.z, -a.y, a.x);
    viewDirs[2] = float3(a.x, a.z, a.y);
    viewDirs[3] = float3(a.x, -a.z, -a.y);
    viewDirs[4] = float3(a.x, -a.y, a.z);
    viewDirs[5] = float3(-a.x, -a.y, -a.z);
}

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void main(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(cubemapSize);

    float3 viewDirs[6];
    getCubemapViewDirs(uv, viewDirs);
    
    for (uint face = 0; face < 6; face++) {
        float3 viewDir = viewDirs[face];

        float3 color = getValFromSkyLUT(skyViewTexture, viewDir, getSunVector());

        skyCubemapTexture.Store(uint3(globalInvocationId.xy, face), float4(color, 1.0));
    }
}
