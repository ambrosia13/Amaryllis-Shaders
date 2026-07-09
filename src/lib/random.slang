public module random;

import aperture;

import math;

// Credit goes to Belmu#4066 for helping me solve my shadow sampling issues through the following two functions.
float2 sincos(float x) {
    return float2(sin(x), cos(x));
}

public float2 diskSampling(float i, float n, float phi) {
    float theta = (i + phi) / n;
    return sincos(theta * TAU * n * 1.618033988749894) * theta;
}

/*
    R2 sequence for offsetting sample positions for fixed noise providers, like blue noise.    
    Adapted from a blue noise sampling function from jbritain in the shaderLABS discord server #snippets.

    Original comment:
    R2 sequence from
    https://extremelearning.com.au/unreasonable-effectiveness-of-quasirandom-sequences/
*/
float2 r2SequenceOffset(int i) {
    const float g = 1.32471795724474602596;
    float a1 = 1.0 / g;
    float a2 = 1.0 / (g * g);

    float2 offset = 128 * float2(fract(0.5 + a1 * i), fract(0.5 + a2 * i));
    return offset;
}

// common interface for random number generators so we don't have to rewrite all the sampling math for different rngs, e.g. blue noise
interface Rng {
    [mutating]
    public uint getUint() {
        return 0; // default impl for float-based random
    }

    [mutating]
    public float getFloat();
}

/*
    Interleaved gradient noise from LowellCamp in the shaderLABS discord server #snippets.
*/
public struct Ign: Rng {
    int2 seed;
    int t;
    int i;

    static const int2 interleave_vec = int2(1125928, 97931);
    static const float interleaved_z = 52.9829189;
    static const float fixed2float = 1.0 / exp2(24.0);
    static const int ref_fixed_point = 1 << 24;

    public static float interleavedGradient(int2 seed, int t) {
        int2 components = int2(seed + 5.588238 * t) * interleave_vec;
        int internal_modulus = (components.x + components.y) & (ref_fixed_point - 1);
        return fract(float(internal_modulus) * (fixed2float * interleaved_z));
    }

    public __init(int2 seed, int t) {
        this.seed = seed;
        this.t = t;
        i = 0;
    }

    [mutating]
    public override float getFloat() {
        float2 offset = r2SequenceOffset(this.i);
        this.i++;

        int2 intOffset = int2(offset);
        return interleavedGradient(seed + intOffset, t);
    }
}

/*
    PCG integer-based hash provided by Belmu (https://github.com/BelmuTM).
*/
public struct Pcg: Rng {
    uint state;

    static void pcg(inout uint seed) {
        uint state = seed * 747796405 + 2891336453;
        uint word = ((state >> ((state >> 28u) + 4u)) ^ state) * 277803737;
        seed = (word >> 22u) ^ word;
    }


    public __init(uint seed) {
        state = seed;
    }

    [mutating]
    public override uint getUint() {
        pcg(this.state);
        return this.state;
    }

    [mutating]
    public override float getFloat() {
        return float(this.getUint()) / float(0xffffffffu);
    }
}

public struct Random<T: Rng> {
    T rng;

    public __init(T rng) {
        this.rng = rng;
    }

    [mutating]
    public float getFloat() {
        return rng.getFloat();
    }

    [mutating]
    public float2 getDiskVector() {
        return float2(
            sqrt(this.rng.getFloat()),
            TAU * this.rng.getFloat()
        );
    }

    [mutating]
    public float3 getUnitVector() {
        float2 xy = float2(this.rng.getFloat(), this.rng.getFloat());
        xy.x *= TAU;
        xy.y = 2.0 * xy.y - 1.0;

        return float3(float2(sin(xy.x), cos(xy.x)) * sqrt(1.0 - xy.y * xy.y), xy.y);
    }

    [mutating]
    public float3 getCosineVector(float3 normal) {
        return normalize(normal + this.getUnitVector());
    }
}