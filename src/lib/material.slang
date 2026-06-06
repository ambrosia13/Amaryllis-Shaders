public module material;

import aperture;

// We store vertex normal and fragment normal in a RGBA16_SNORM texture, with the normals storing the first two
// channels in world space; the third channel will be reconstructed later with the sign bits stored in meta8.
// 
// f0, roughness, sssAmount, and the meta8 bitfield are stored in a RGBA8_UINT texture. The first three components
// are simply stored in an unsigned normalized fashion, while the meta8 bitfield is stored directly. The meta8 bitfield
// contains two flags for the sign of both the vertex and fragment normal, and a flag for water, with the rest unused.
// 
// Finally, the lighting texture is an RGBA8 storing the blocklight, skylight, ambient occlusion, and emission
// value as unsigned normalized values.
public struct Material {
    public float3 vertexNormal;
    public float f0;
    public float3 fragNormal;
    float roughness;

    float blockLight;
    float skyLight;
    float ambientOcclusion;
    float emission;
    
    float sssAmount;
    uint meta;

    private static const uint META_VERTEX_NORMAL_SIGN_BIT = 0b10000000;
    private static const uint META_FRAG_NORMAL_SIGN_BIT = 0b01000000;
    private static const uint META_IS_WATER_BIT = 0b00100000;

    // constructed in object shader using vertex attributes and/or pbr texture reads and/or block ids
    public __init(
        float3 vertexNormal,
        float3 fragNormal,

        float f0,
        float roughness,
        float sssAmount,
        bool isWater,

        float blockLight,
        float skyLight,
        float ambientOcclusion,
        float emission
    ) {
        meta = 0;
        
        this.vertexNormal = vertexNormal;
        this.fragNormal = fragNormal;
        meta |= vertexNormal.z < 0.0 ? META_VERTEX_NORMAL_SIGN_BIT : 0;
        meta |= fragNormal.z < 0.0 ? META_FRAG_NORMAL_SIGN_BIT : 0;

        this.f0 = f0;
        this.roughness = roughness;
        this.sssAmount = sssAmount;
        meta |= isWater ? META_IS_WATER_BIT : 0;

        this.blockLight = blockLight;
        this.skyLight = skyLight;
        this.ambientOcclusion = ambientOcclusion;
        this.emission = emission;
    }

    public bool isWater() {
        return (meta & META_IS_WATER_BIT) != 0;
    }

    public static Material unpack(float4 normalSample, uint4 pbrSample, float4 lightingSample) {
        Material mat;

        // simplest values first
        mat.f0 = float(pbrSample.x) / 255.0;
        mat.roughness = float(pbrSample.y) / 255.0;
        mat.sssAmount = float(pbrSample.z) / 255.0;
        mat.meta = pbrSample.w & 0xFF;

        mat.blockLight = lightingSample.x;
        mat.skyLight = lightingSample.y;
        mat.ambientOcclusion = lightingSample.z;
        mat.emission = lightingSample.w;

        // normal unpacking
        float4 normalSampleSquared = normalSample * normalSample;
        float vertexNormalSign = (mat.meta & META_VERTEX_NORMAL_SIGN_BIT) == 0 ? 1.0 : -1.0;
        float fragmentNormalSign = (mat.meta & META_FRAG_NORMAL_SIGN_BIT) == 0 ? 1.0 : -1.0;

        mat.vertexNormal.x = normalSample.x;
        mat.vertexNormal.y = normalSample.y;
        mat.vertexNormal.z = vertexNormalSign * sqrt(saturate(1.0 - normalSampleSquared.x - normalSampleSquared.y));
        mat.vertexNormal = normalize(mat.vertexNormal);

        mat.fragNormal.x = normalSample.z;
        mat.fragNormal.y = normalSample.w;
        mat.fragNormal.z = fragmentNormalSign * sqrt(saturate(1.0 - normalSampleSquared.z - normalSampleSquared.w));
        mat.fragNormal = normalize(mat.fragNormal);

        return mat;
    }

    public float4 packNormals() {
        return float4(vertexNormal.xy, fragNormal.xy);
    }

    public uint4 packPbr() {
        // convert float values to unsigned normalized
        uint f0Unorm = uint(floor(f0 * 255.0)) & 0xFF;
        uint roughnessUnorm = uint(floor(roughness * 255.0)) & 0xFF;
        uint sssAmountUnorm = uint(floor(sssAmount * 255.0)) & 0xFF;

        return uint4(f0Unorm, roughnessUnorm, sssAmountUnorm, meta);
    }

    public float4 packLight() {
        return float4(blockLight, skyLight, ambientOcclusion, emission);
    }
}