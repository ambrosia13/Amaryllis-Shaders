import lib.atmosphere;

extern static const uint transmittanceTextureWidth; 
extern static const uint transmittanceTextureHeight; 

RWTexture2D<float4> transmittanceLookupTexture;

[[numthreads(8, 8, 1)]]
[[shader("compute")]]
void transmittance(uint3 globalInvocationId: SV_DispatchThreadID) {
    float2 uv = float2(globalInvocationId.xy) / float2(transmittanceTextureWidth, transmittanceTextureHeight);
}
