public module space;

import aperture;

float3 fromScreenSpace(float3 screenSpacePos, float4x4 matrix) {
    // only the x and y components (screen coords) need to be remapped
    float3 ndc = screenSpacePos;
    ndc.xy = ndc.xy * 2.0 - 1.0;

    float4 temp = mul(matrix, float4(ndc, 1.0));
    return temp.xyz / temp.w;
}

float3 toScreenSpace(in float3 pos, in float4x4 matrix) {
    float4 ndc = mul(matrix, float4(pos, 1.0));
    float3 temp = (ndc.xyz / ndc.w);
    // only the x and y components (screen coords) need to be remapped
    temp.xy = temp.xy * 0.5 + 0.5;
    return temp;
}

public float3 screenSpaceToSceneSpace(float3 screenSpacePos) {
    return fromScreenSpace(screenSpacePos, mul(ap.camera.viewInv, ap.camera.projectionInv));
}

public float3 sceneSpaceToScreenSpace(float3 sceneSpacePos) {
    return toScreenSpace(sceneSpacePos, mul(ap.camera.view, ap.camera.projection));
}

public float3 screenSpaceToViewSpace(float3 screenSpacePos) {
    return fromScreenSpace(screenSpacePos, ap.camera.projectionInv);
}

public float3 viewSpaceToScreenSpace(float3 viewSpacePos) {
    return toScreenSpace(viewSpacePos, ap.camera.projection);
}

public float linearizeDepth(float depth) {
    return ap.camera.near * ap.camera.far / (ap.camera.far - (depth * (ap.camera.far - ap.camera.near)));
}