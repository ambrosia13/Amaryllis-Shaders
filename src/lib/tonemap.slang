module tonemap;

import aperture;

import lib.color;

// Extracted from JustJohn's tone mapper, see below.
static const float3x3 XYZ_to_sRGB = float3x3(
     3.2404542, -1.5371385, -0.4985314,
	-0.9692660,  1.8760108,  0.0415560,
	 0.0556434, -0.2040259,  1.0572252
);

static const float3x3 sRGB_to_XYZ = float3x3(
    0.4124564, 0.3575761, 0.1804375,
	0.2126729, 0.7151522, 0.0721750,
	0.0193339, 0.1191920, 0.9503041
);

static const float3x3 XYZ_to_LMS = float3x3(
        0.4002, 0.7076, -0.0808,
       -0.2263, 1.1653,  0.0457,
        0.0,    0.0,     0.9182
);

static const float3x3 LMS_to_XYZ = float3x3(
    1.86006661e+00, -1.12948008e+00,  2.19898303e-01,
    3.61222925e-01,  6.38804306e-01, -7.12750153e-06,
    0.00000000e+00,  0.00000000e+00,  1.08908734e+00
);

static const float3x3 sRGB_to_LMS = float3x3(
    0.27268655, 0.65552284, 0.07179061,
    0.09949164, 0.77724267, 0.12326569,
    0.02402541, 0.09303149, 0.8829431
);

static const float3x3 LMS_to_sRGB = float3x3(
    5.28471971, -4.48054731,  0.1958275,
    -0.66477748,  1.87208299, -0.20730536,
    -0.07375599, -0.07533408,  1.14909005
);

/*
    "ZCAM Tonemapper" by JustJohn. Taken from https://www.shadertoy.com/view/dlGBDD; code released under the MIT license.

    The original license text is shown below.

    MIT License

    Copyright (c) 2023 John Payne

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
namespace justjohn {
    // eotf_pq parameters
    static const float Lp = 10000.0;
    static const float m1 = 2610.0 / 16384.0;
    static const float m2 = 1.7 * 2523.0 / 32.0;
    static const float c1 = 107.0 / 128.0;
    static const float c2 = 2413.0 / 128.0;
    static const float c3 = 2392.0 / 128.0;

    float3 eotf_pq(float3 x) {
        x = sign(x) * pow(abs(x), float3(1.0 / m2));
        x = sign(x) * pow((abs(x) - c1) / (c2 - c3 * abs(x)), float3(1.0 / m1)) * Lp;
        return x;
    }

    float3 eotf_pq_inverse(float3 x) {
        x /= Lp;
        x = sign(x) * pow(abs(x), float3(m1));
        x = sign(x) * pow((c1 + c2 * abs(x)) / (1.0 + c3 * abs(x)), float3(m2));
        return x;
    }

    // XYZ <-> ICh parameters
    static const float W = 140.0;
    static const float b = 1.15;
    static const float g = 0.66;

    float3 XYZ_to_ICh(float3 XYZ) {
        XYZ *= W;
        XYZ.xy = float2(b, g) * XYZ.xy - (float2(b, g) - 1.0) * XYZ.zx;
        
        const float3x3 XYZ_to_LMS = (float3x3(
            0.41479,   0.579999, 0.014648,
            -0.20151,   1.12065,  0.0531008,
            -0.0166008, 0.2648,   0.66848));
        
        float3 LMS = mul(XYZ_to_LMS, XYZ);
        LMS = eotf_pq_inverse(LMS);
        
        const float3x3 LMS_to_Iab = (float3x3(
            0.0,       1.0,      0.0,
            3.524,    -4.06671,  0.542708,
            0.199076,  1.0968,  -1.29588));
        
        float3 Iab = mul(LMS_to_Iab, LMS);
        
        float I = eotf_pq(float3(Iab.x)).x / W;
        float C = length(Iab.yz);
        float h = atan2(Iab.z, Iab.y);
        return float3(I, C, h);
    }

    float3 ICh_to_XYZ(float3 ICh) {
        float3 Iab;
        Iab.x = eotf_pq_inverse(float3(ICh.x * W)).x;
        Iab.y = ICh.y * cos(ICh.z);
        Iab.z = ICh.y * sin(ICh.z);
        
        const float3x3 Iab_to_LMS = (float3x3(
            1.0, 0.2772,  0.1161,
            1.0, 0.0,     0.0,
            1.0, 0.0426, -0.7538));
        
        float3 LMS = mul(Iab_to_LMS, Iab);
        LMS = eotf_pq(LMS);
        
        const float3x3 LMS_to_XYZ = (float3x3(
            1.92423, -1.00479,  0.03765,
            0.35032,  0.72648, -0.06538,
            -0.09098, -0.31273,  1.52277));
        
        float3 XYZ = mul(LMS_to_XYZ, LMS);
        XYZ.x = (XYZ.x + (b - 1.0) * XYZ.z) / b;
        XYZ.y = (XYZ.y + (g - 1.0) * XYZ.x) / g;
        return XYZ / W;
    }

    float sRGB_to_Y(float3 sRGB) {
        return mul(sRGB_to_XYZ, sRGB).y;
    }

    bool in_sRGB_gamut(float3 ICh) {
        float3 sRGB = mul(XYZ_to_sRGB, ICh_to_XYZ(ICh));
        return all(sRGB >= float3(0.0)) && all(sRGB <= float3(1.0));
    }

    float3 tonescale(float3 x, float a, float b) {
        x = pow(x, float3(a));
        x = x / (x + exp(-b));
        x *= x;
        return x;
    }

    float f(float t, float3 p, float3 rgb, float Y) {
        return sRGB_to_Y(rgb + pow(float3(t), p) * (1.0 - rgb)) - Y;
    }

    float dfdt(float t, float3 p, float3 rgb) {
        return sRGB_to_Y(p * pow(float3(t), p - 1.0) * (1.0 - rgb));
    }
}

public float3 justjohnTonemap(float3 sRGB) {
    float3 linearSrgb;

    const uint mode = 3;

    if (mode == 0) {
        sRGB *= 3.0;
        float3 chroma = justjohn.tonescale(sRGB, 0.75f, -0.23);
        chroma /= mul(sRGB_to_XYZ, chroma).y;
        
        float Y = justjohn.tonescale(mul(sRGB_to_XYZ, sRGB).yyy, 0.75, 0.0).y;
        linearSrgb = clamp(chroma * Y, 0.0, 1.0);
    } else if (mode == 1) {
        float Y = justjohn.tonescale(mul(sRGB_to_XYZ, sRGB).yyy, 0.75, 0.0).y;
        
        float achromatic = max(sRGB.r, max(sRGB.g, sRGB.b));
        sRGB *= justjohn.tonescale(float3(achromatic), 0.75, 0.0).x / achromatic;
        
        if (Y > justjohn.sRGB_to_Y(sRGB)) {
            float3 p = float3(1.4, 1.0, 1.1);
            float t = 1.0;
            for (int i = 0; i < 4; i++)
                t = t - justjohn.f(t, p, sRGB, Y) / justjohn.dfdt(t, p, sRGB);
            
            sRGB = lerp(sRGB, float3(1.0), pow(float3(t), p));
        } else {
            float t = (Y - justjohn.sRGB_to_Y(sRGB)) / (1.0 - justjohn.sRGB_to_Y(sRGB));
            sRGB = lerp(sRGB, float3(1.0), t);
        }
        
        linearSrgb = sRGB;
    } else if (mode == 2) {
        float3 LMS = mul(XYZ_to_LMS, mul(sRGB_to_XYZ, sRGB));
        
        LMS = justjohn.tonescale(LMS, 0.75, 0.0);
        
        sRGB = mul(XYZ_to_sRGB, mul(LMS_to_XYZ, LMS));
        linearSrgb = sRGB;
    } else {
        float3 ICh = justjohn.XYZ_to_ICh(mul(sRGB_to_XYZ, sRGB));
        
        const float s0 = 0.71;
        const float s1 = 1.04;
        const float p = 1.40;
        const float t0 = 0.01;
        float n = s1 * pow(ICh.x / (ICh.x + s0), p);
        ICh.x = clamp(n * n / (n + t0), 0.0, 1.0);
        
        if (!justjohn.in_sRGB_gamut(ICh))
        {
            float C = ICh.y;
            ICh.y -= 0.5 * C;
            
            for (float i = 0.25; i >= 1.0 / 256.0; i *= 0.5)
            {
                ICh.y += (justjohn.in_sRGB_gamut(ICh) ? i : -i) * C;
            }
        }
        
        linearSrgb = mul(XYZ_to_sRGB, justjohn.ICh_to_XYZ(ICh));
    }

    return (linearSrgb);
}

/*
    The following four functions are FREX adaptations for common aces fit tone mapping:
    https://github.com/vram-guild/frex/blob/1.19/common/src/main/resources/assets/frex/shaders/lib/color.glsl

    FREX is under the LGPL v3.0 license, and according to the source file, portions were taken from Wisdon shaders by bobcao3, 
    under the Apache v2.0 license.

    Changes were made to adapt the code from GLSL to Slang.
*/
namespace acesFit {
    public static const float3x3 ACES_INPUT_MATRIX = float3x3(
        float3(0.59719, 0.07600, 0.02840),
        float3(0.35458, 0.90834, 0.13383),
        float3(0.04823, 0.01566, 0.83777)
    );

    // ODT_SAT => XYZ => D60_2_D65 => sRGB
    public static const float3x3 ACES_OUTPUT_MATRIX = float3x3(
        float3(1.60475, -0.10208, -0.00327),
        float3(-0.53108, 1.10813, -0.07276),
        float3(-0.07367, -0.00605, 1.07602)
    );

    float3 rrtAndOdtfFit(float3 v) {
        float3 a = v * (v + 0.0245786) - 0.000090537;
        float3 b = v * (0.983729 * v + 0.4329510) + 0.238081;

        return a / b;
    }
}

public float3 acesFitTonemap(float3 color) {
    color = mul(color, acesFit.ACES_INPUT_MATRIX);
    color = acesFit.rrtAndOdtfFit(color);

    float3 linear = mul(color, acesFit.ACES_OUTPUT_MATRIX);
    return (linear);
}

/*
    AgX approximations from https://www.shadertoy.com/view/cd3XWr.
*/
namespace agxApprox {
    float3 agxDefaultContrastApprox(float3 x) {
        float3 x2 = x * x;
        float3 x4 = x2 * x2;
        
        return + 15.5     * x4 * x2
                - 40.14    * x4 * x
                + 31.96    * x4
                - 6.868    * x2 * x
                + 0.4298   * x2
                + 0.1191   * x
                - 0.00232;
    }

    float3 agx(float3 val) {
        const float3x3 agx_mat = float3x3(
            0.842479062253094, 0.0423282422610123, 0.0423756549057051,
            0.0784335999999992,  0.878468636469772,  0.0784336,
            0.0792237451477643, 0.0791661274605434, 0.879142973793104
        );
            
        const float min_ev = -12.47393f;
        const float max_ev = 4.026069f;

        // Input transform
        val = mul(agx_mat, val);
        
        // Log2 space encoding
        val = clamp(log2(val), min_ev, max_ev);
        val = (val - min_ev) / (max_ev - min_ev);
        
        // Apply sigmoid function approximation
        val = agxDefaultContrastApprox(val);

        return val;
    }

    float3 agxEotf(float3 val) {
        const float3x3 agx_mat_inv = float3x3(
            1.19687900512017, -0.0528968517574562, -0.0529716355144438,
            -0.0980208811401368, 1.15190312990417, -0.0980434501171241,
            -0.0990297440797205, -0.0989611768448433, 1.15107367264116
        );
            
        // Undo input transform
        val = mul(agx_mat_inv, val);
        
        // sRGB IEC 61966-2-1 2.2 Exponent Reference EOTF Display
        val = linearizeSrgb(val);

        return val;
    }

    float3 agxLook(float3 val) {  
        // Default
        float3 offset = float3(0.0);
        float3 slope = float3(1.0);
        float3 power = float3(1.0);
        float sat = 1.0;
        
        // #define AGX_LOOK 2
        // #if AGX_LOOK == 1
        //   // Golden
        //   slope = float3(1.0, 0.9, 0.5);
        //   power = float3(0.8);
        //   sat = 0.8;
        // #elif AGX_LOOK == 2
        //   // Punchy
        //   slope = float3(1.0);
        //   power = float3(1.35, 1.35, 1.35);
        //   sat = 1.4;
        // #endif
        
        // ASC CDL
        val = pow(val * slope + offset, power);
        
        const float3 lw = float3(0.2126, 0.7152, 0.0722);
        float luma = dot(val, lw);
        
        return luma + sat * (val - luma);
    }
}

public float3 agxApproxTonemap(float3 color) {
    color = agxApprox.agx(color);
    color = agxApprox.agxLook(color);
    color = agxApprox.agxEotf(color);

    return color;
}

/*
    Taken from https://allenwp.com/blog/2025/05/29/allenwp-tonemapping-curve, released under the MIT License.

    The original license text is shown below.

    Copyright (c) 2025 Allen Pestaluky

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/
// allenwp tonemapping curve; developed for use in the Godot game engine
// Source and details: https://allenwp.com/blog/2025/05/29/allenwp-tonemapping-curve/
// Input must be a linear scene value
float3 allenwpTonemap(
    float3 x,
    float output_max_value,
    float awp_contrast,
    float awp_toe_a,
    float awp_slope,
    float awp_w,
    float awp_shoulder_max
) {
	// This constant must match the CPU-side code that calculates the parameters.
	// 18% "middle grey" is perceptually 50% of the lightness of reference white.
	const float awp_crossover_point = 0.1841865;

	x = max(x, 0.0); // Negative input causes undefined behaviour from pow function!

	// Reinhard-like shoulder:
	float3 s = x - awp_crossover_point;
	float3 slope_s = awp_slope * s;
	s = slope_s * (1.0 + s / awp_w) / (1.0 + (slope_s / awp_shoulder_max));
	s += awp_crossover_point;

	// Sigmoid power function toe:
	float3 t = pow(x, float3(awp_contrast));
	t = t / (t + awp_toe_a);

	return select(x < float3(awp_crossover_point), t, s);
}


// public enum CameraResponseCurve {
//     Advantix_100 = 0,
//     Advantix_200 = 3,
//     Advantix_400 = 6,
//     Ektachrome_100 = 9,
//     Ektachrome_100_plus = 12,
//     Ektachrome_320T = 15,
//     Ektachrome_400X = 18,
//     Ektachrome_64 = 21,
//     Ektachrome_64T = 24,
//     Ektachrome_E100S = 27,
//     F125 = 30,
//     F250 = 33,
//     F400 = 36,
//     FCI = 39,
//     Gold_100 = 42,
//     Gold_200 = 45,
//     Kodachrome_200 = 48,
//     Kodachrome_25 = 51,
//     Kodachrome_64 = 54,
//     Max_Zoom_800 = 57,
//     Portra_100T = 60,
//     Portra_160NC = 63,
//     Portra_160VC = 66,
//     Portra_400NC = 69,
//     Portra_400VC = 72,
//     Portra_800 = 75,
//     agfachrome_ctpecisa_200 = 78,
//     agfachrome_ctprecisa_100 = 81,
//     agfachrome_rsx2_050 = 84,
//     agfachrome_rsx2_100 = 87,
//     agfachrome_rsx2_200 = 90,
//     agfacolor_futura_100 = 93,
//     agfacolor_futura_200 = 96,
//     agfacolor_futura_400 = 99,
//     agfacolor_futuraII_100 = 102,
//     agfacolor_futuraII_200 = 105,
//     agfacolor_futuraII_400 = 108,
//     agfacolor_hdc_100_plus = 111,
//     agfacolor_hdc_200_plus = 114,
//     agfacolor_hdc_400_plus = 117,
//     agfacolor_optimaII_100 = 120,
//     agfacolor_optimaII_200 = 123,
//     agfacolor_ultra_050 = 126,
//     agfacolor_vista_100 = 129,
//     agfacolor_vista_200 = 132,
//     agfacolor_vista_400 = 135,
//     agfacolor_vista_800 = 138,
// }

// Texture2D<float> dorfCurves;

// public float3 applyCameraResponseCurve(float3 color, CameraResponseCurve curve) {
//     float row = float(uint(curve)) + 0.5;
    
//     float red = dorfCurves.Sample(apt_linearSampler, float2(color.r, row / 141.0));
//     float green = dorfCurves.Sample(apt_linearSampler, float2(color.g, (row + 1.0) / 141.0));
//     float blue = dorfCurves.Sample(apt_linearSampler, float2(color.b, (row + 2.0) / 141.0));

//     float3 response = float3(red, green, blue);

//     // very close to linear tonemap to soften the clipping
//     return (response);
// }
