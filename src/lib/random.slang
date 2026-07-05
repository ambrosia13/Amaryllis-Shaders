public module random;

import math;

void pcg(inout uint seed) {
    uint state = seed * 747796405 + 2891336453;
    uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737;
    seed = (word >> 22u) ^ word;
}

public struct Random {
    uint state;

    public __init(uint seed) {
        state = seed;
    }

    [mutating]
    public uint getUint() {
        pcg(this.state);
        return this.state;
    }

    [mutating]
    public float getFloat() {
        return float(this.getUint()) / float(0xffffffffu);
    }

    [mutating]
    public float2 getDiskVector() {
        return float2(
            sqrt(this.getFloat()),
            TAU * this.getFloat()
        );
    }

    [mutating]
    public float3 getUnitVector() {
        float2 xy = float2(this.getFloat(), this.getFloat());
        xy.x *= TAU;
        xy.y = 2.0 * xy.y - 1.0;

        return float3(float2(sin(xy.x), cos(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
    }

    [mutating]
    public float3 getCosineVector(float3 normal) {
        return normalize(normal + this.getUnitVector());
    }
}