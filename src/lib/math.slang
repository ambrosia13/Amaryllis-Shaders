public module math;

public static const float PI = 3.1415926535897932384626433832795;
public static const float HALF_PI = 1.57079632679489661923;
public static const float TAU = 6.2831853071795864769252867665590;

public static const float E = 2.718281828459045235360287471352;

public vector<float, N> pow2<uint N>(vector<float, N> x) { 
    return x * x; 
}

public vector<float, N> linearstep<uint N>(float a, float b, vector<float, N> x) {
    return saturate((x - a) / (b - a));
}

// ...because for some reason slang doesn't have this
public vector<float, N> mod<int N>(vector<float, N> x, float y) {
    return x - y * floor(x / y);
}

// Angle should be in radians
float2x2 rotationMatrix(float angle) {
    float s = sin(angle);
    float c = cos(angle);
    return float2x2(c, s, -s, c);
}
