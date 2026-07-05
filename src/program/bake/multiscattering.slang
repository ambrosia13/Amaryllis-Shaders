import lib.atmosphere;

extern static const uint multiscatteringTextureWidth; 
extern static const uint multiscatteringTextureHeight; 

Texture2D transmittanceLookupTexture;
RWTexture2D<float4> multiscatteringLookupTexture;


[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void multiscattering(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(multiscatteringTextureWidth, multiscatteringTextureHeight);
}
