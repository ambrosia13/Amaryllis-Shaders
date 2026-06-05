import aperture;

public struct Material {
    public float3 vertexNormal;
    public float f0;
    public float3 fragNormal;
    float ambientOcclusion;
    float2 light;
    float roughness;
}