/*
    The following two types and three functions are taken from the FREX utility libraries at
    https://github.com/vram-guild/frex/blob/1.19/common/src/main/resources/assets/frex/shaders/lib/face.glsl.
*/

static const float3x3[6] FACE_UV_MATRIX = float3x3[6](
    float3x3(1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0),
    float3x3(1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0),
    float3x3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0),
    float3x3(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0),
    float3x3(0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0),
    float3x3(0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0)
);

enum Face {
    DOWN,
    UP,
    NORTH,
    SOUTH,
    WEST,
    EAST,
}

// Returns the FACE_ constant most consistent with the
// provided world-space normal.
//
// Will return garbage for normals in screen space.
public int getFaceIndex(float3 normal) {
	float3 a = abs(normal);
	float m = max(max(a.x, a.y), a.z);

	return a.x == m ? (normal.x > 0 ? Face.EAST : Face.WEST)
	: a.y == m ? (normal.y > 0 ? Face.UP : Face.DOWN)
	: (normal.z > 0 ? Face.SOUTH : Face.NORTH);
}

// Estimates UV coordinates for a world-space position
// and world-space normal, assuming texture coordinates
// are from the 0,0 face corner to the opposite corner.
//
// The result is similar to "locked-uv" coordinate mapping
// in block/item models.
//
// Will return garbage for vertex or normals in screen space.
public float2 getFaceUv(float3 pos, float3 normal) {
	float3x3 m = FACE_UV_MATRIX[getFaceIndex(normal)];
	float3 result = mul(pos, m);
	return result.xy;
}

// Estimates UV coordinates for a world-space position
// and world-space normal, assuming texture coordinates
// are from the 0,0 face corner to the opposite corner.
//
// The result is similar to "locked-uv" coordinate mapping
// in block/item models.
//
// Will return garbage for vertex or normals in screen space.
public float2 getFaceUv(float3 pos, int face) {
	float3x3 m = FACE_UV_MATRIX[face];
	float3 result = mul(pos, m);
	return result.xy;
}
