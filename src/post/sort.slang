import aperture;

import lib.material;

// we want to blend with the deferred-lit solid texture
// #define def_solidLitTexture mainTexture_a

Texture2D solidLitTexture;
Texture2D<float4> solidMatNormalsTexture;
Texture2D<uint4> solidMatPbrTexture;
Texture2D<float4> solidMatLightTexture;

// translucents are forward rendered, so this is the lit translucent
Texture2D translucentAlbedoTexture;
Texture2D<float4> translucentMatNormalsTexture;
Texture2D<uint4> translucentMatPbrTexture;
Texture2D<float4> translucentMatLightTexture;

struct FragmentOutput {
    float4 color;
    float4 matNormals;
    uint4 matPbr;
    float4 matLight;
}

[[shader("pixel")]]
FragmentOutput main(float2 pos: SV_Position) {
    uint2 coord = uint2(pos);

    float solidDepth = ap.opaqueDepth[coord];
    float translucentDepth = max(ap.handDepth[coord], ap.depth[coord]);

    // start the blending with solid as a background
    float3 compositeColor = solidLitTexture[coord].rgb;
    float4 compositeMatNormalsSample = solidMatNormalsTexture[coord];
    uint4 compositeMatPbrSample = solidMatPbrTexture[coord];
    float4 compositeMatLightSample = solidMatLightTexture[coord];
    
    float4 translucentColor = translucentAlbedoTexture[coord];
    float4 translucentMatNormalsSample = translucentMatNormalsTexture[coord];
    uint4 translucentMatPbrSample = translucentMatPbrTexture[coord];
    float4 translucentMatLightSample = translucentMatLightTexture[coord];

    // blend translucents, condition needs to be changed for rev-z
    if (translucentDepth > solidDepth) {
        compositeColor = lerp(compositeColor, translucentColor.rgb, translucentColor.a);
        
        compositeMatNormalsSample = translucentMatNormalsSample;
        compositeMatPbrSample = translucentMatPbrSample;
        compositeMatLightSample = translucentMatLightSample;
    }

    FragmentOutput output;

    output.color = float4(compositeColor, 1.0);
    output.matNormals = compositeMatNormalsSample;
    output.matPbr = compositeMatPbrSample;
    output.matLight = compositeMatLightSample;

    return output;
}
