// Outlast 2 HDR Tonemap Shader
// Modified from original for HDR support with hue-preserving tone mapping

cbuffer _Globals : register(b0)
{
  float4 SceneShadowsAndDesaturation : packoffset(c0);
  float4 SceneInverseHighLights : packoffset(c1);
  float4 SceneMidTones : packoffset(c2);
  float4 SceneScaledLuminanceWeights : packoffset(c3);
  float4 SceneColorize : packoffset(c4);
  float4 GammaColorScaleAndInverse : packoffset(c5);
  float4 GammaOverlayColor : packoffset(c6);
  float4 RenderTargetExtent : packoffset(c7);
  float4 PackedParameters : packoffset(c8);
  float4 MinMaxBlurClamp : packoffset(c9);
  float4 RenderTargetClampParameter : packoffset(c10);
  float4 MotionBlurMaskScaleAndBias : packoffset(c11);
  float4x4 ScreenToWorld : packoffset(c12);
  float4x4 PrevViewProjMatrix : packoffset(c16);
  float4 StaticVelocityParameters : packoffset(c20) = {0.5,-0.5,0.0125000002,0.0222222228};
  float4 DynamicVelocityParameters : packoffset(c21) = {0.0250000004,-0.0444444455,-0.0500000007,0.088888891};
  float StepOffsetsOpaque[7] : packoffset(c22);
  float StepWeightsOpaque[7] : packoffset(c29);
  float4 Uncharted2TonemapParams1 : packoffset(c36);
  float4 Uncharted2TonemapParams2 : packoffset(c37);
  float2 RedBarrelsTonemapCutoffs : packoffset(c38);
  float2 RedBarrelsTonemapToe : packoffset(c38.z);
  float2 RedBarrelsTonemapMidtones : packoffset(c39);
  float4 RedBarrelsTonemapShoulder : packoffset(c40);
  float3 LensDirtTint : packoffset(c41);
  float2 LensDirtScale : packoffset(c42);
  float4 BloomTintAndScreenBlendThreshold : packoffset(c43);
  float4 ImageAdjustments1 : packoffset(c44);
  float4 FullResMaskRect : packoffset(c45);
  float4 HalfResMaskRect : packoffset(c46);
  float4 QuarterResMaskRect : packoffset(c47);
  float4 DOFKernelSize : packoffset(c48);
  float2 RedBarrelsDOFKernelSize : packoffset(c49);
  float4 Exposure : packoffset(c50);
  float3 RedBarrelsDOFParams : packoffset(c51);
  float4 UVScaleBias : packoffset(c52);
  float4 SceneCoordinate1ScaleBias : packoffset(c53);
  float4 SceneCoordinate2ScaleBias : packoffset(c54);
  float4 SceneCoordinate3ScaleBias : packoffset(c55);
  float2 InvViewSize : packoffset(c56);
  float VignetteParams : packoffset(c56.z);
};

// HDR injection constants (injected by RenoDX)
cbuffer HDRConstants : register(b13)
{
  float tone_map_type : packoffset(c0.x);
  float peak_white_nits : packoffset(c0.y);
  float diffuse_white_nits : packoffset(c0.z);
  float graphics_white_nits : packoffset(c0.w);
  float gamma_correction : packoffset(c1.x);
};

SamplerState SceneColorTextureSampler_s : register(s2);
SamplerState FilterColor1TextureSampler_s : register(s3);
SamplerState LensDirtTextureSampler_s : register(s4);
SamplerState ColorGradingLUTSampler_s : register(s5);
SamplerState MotionBlurAmountTextureSampler_s : register(s6);
SamplerState LowResPostProcessBufferSampler_s : register(s7);
Texture2D<float4> SceneColorTexture : register(t0);
Texture2D<float4> FilterColor1Texture : register(t1);
Texture2D<float4> LensDirtTexture : register(t2);
Texture3D<float4> ColorGradingLUT : register(t3);
Texture2D<float4> MotionBlurAmountTexture : register(t4);
Texture2D<float4> LowResPostProcessBuffer : register(t5);

#define cmp -

// Convert linear RGB to Oklab for hue-preserving tone mapping
float3 LinearToOklab(float3 c)
{
  float l = 0.4122214708 * c.r + 0.5363325363 * c.g + 0.0514459929 * c.b;
  float m = 0.2119034982 * c.r + 0.6806995451 * c.g + 0.1073969566 * c.b;
  float s = 0.0883024619 * c.r + 0.0817845529 * c.g + 0.8943868922 * c.b;

  l = cbrt(l);
  m = cbrt(m);
  s = cbrt(s);

  return float3(
    0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
  );
}

// Convert Oklab back to linear RGB
float3 OklabToLinear(float3 oklab)
{
  float l = oklab.x + 0.3963377774 * oklab.y + 0.2158037573 * oklab.z;
  float m = oklab.x - 0.1055613458 * oklab.y - 0.0638541728 * oklab.z;
  float s = oklab.x - 0.0894841775 * oklab.y - 1.2914855480 * oklab.z;

  l = l * l * l;
  m = m * m * m;
  s = s * s * s;

  return float3(
    4.0767416621 * l - 3.3077363322 * m + 0.2309101289 * s,
    -1.2684380046 * l + 2.6097574011 * m - 0.3413193761 * s,
    -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
  );
}

// RenoDRT tone mapping curve for HDR
float3 RenoDRTTonemap(float3 color, float peak_nits, float game_nits)
{
  // Normalize to 0-1 range based on game's reference white
  float3 normalized = color / game_nits;
  
  // Apply smooth S-curve for perceptually pleasing tone mapping
  // Toe (shadows): gentle curve up
  // Midtones: linear expansion
  // Shoulder (highlights): smooth roll-off to peak
  
  float3 toe = normalized * normalized * 0.5;
  
  // Smooth transition point
  float transition = 0.2;
  float3 useToe = step(float3(transition, transition, transition), normalized);
  
  // Linear midtone expansion
  float3 midtone = normalized;
  
  // Shoulder with smooth roll-off
  float shoulder_strength = (peak_nits / game_nits - 1.0);
  float3 shoulder = normalized + shoulder_strength * normalized * (1.0 - normalized);
  
  // Blend between toe and shoulder based on normalized value
  float3 result = lerp(toe, shoulder, useToe);
  
  // Expand to peak nits
  result = result * peak_nits;
  
  return result;
}

// Simple hue-preserving expansion
float3 ExpandToHDR(float3 sdr_color, float peak_nits, float game_nits)
{
  // Convert to Oklab
  float3 oklab = LinearToOklab(sdr_color);
  
  // Expand lightness while preserving hue (a and b channels)
  float expanded_l = oklab.x;
  
  // Apply tone curve to lightness
  if (tone_map_type > 0.5)  // RenoDX mode
  {
    // Scale lightness to peak nits
    expanded_l = expanded_l * (peak_nits / game_nits);
    
    // Apply slight compression to prevent blown out highlights
    expanded_l = expanded_l / (1.0 + expanded_l * 0.5);
  }
  else  // Vanilla mode - minimal tone mapping
  {
    expanded_l = expanded_l * (peak_nits / game_nits);
  }
  
  // Reconstruct in Oklab and convert back to linear
  float3 expanded_oklab = float3(expanded_l, oklab.y, oklab.z);
  float3 hdr_color = OklabToLinear(expanded_oklab);
  
  return hdr_color;
}

void main(
  float4 v0 : TEXCOORD0,
  float4 v1 : TEXCOORD1,
  float2 v2 : TEXCOORD2,
  out float4 o0 : SV_Target0)
{
  float4 r0, r1, r2, r3;
  uint4 bitmask, uiDest;
  float4 fDest;

  r0.x = sqrt(PackedParameters.w);
  r0.x = 1 + -r0.x;
  r0.y = MotionBlurAmountTexture.Sample(MotionBlurAmountTextureSampler_s, v1.zw).x;
  r0.x = min(r0.y, r0.x);
  r0.yzw = SceneColorTexture.SampleLevel(SceneColorTextureSampler_s, v1.xy, 0).xyz;
  r1.xyz = LowResPostProcessBuffer.Sample(LowResPostProcessBufferSampler_s, v1.zw).xyz;
  r1.xyz = Exposure.xxx * r1.xyz;
  r0.yzw = r0.yzw * Exposure.xxx + -r1.xyz;
  r0.xyz = r0.xxx * r0.yzw + r1.xyz;
  r0.xyz = min(float3(65503, 65503, 65503), r0.xyz);
  
  r1.xy = InvViewSize.xy * v2.xy;
  r1.xy = LensDirtScale.xy * r1.xy;
  r1.xyz = LensDirtTexture.Sample(LensDirtTextureSampler_s, r1.xy).xyz;
  r1.xyz = r1.xyz * LensDirtTint.xyz + BloomTintAndScreenBlendThreshold.xyz;
  r2.xyz = FilterColor1Texture.Sample(FilterColor1TextureSampler_s, v0.zw).xyz;
  r1.xyz = r2.xyz * r1.xyz;
  r0.xyz = r1.xyz * Exposure.xxx + r0.xyz;
  
  // Vignette
  r1.xy = v2.xy * InvViewSize.xy + float2(-0.5, -0.5);
  r0.w = dot(r1.xy, r1.xy);
  r0.w = sqrt(r0.w);
  r0.w = -r0.w * 1.25 + 1;
  r0.w = max(0, r0.w);
  r0.w = r0.w * r0.w + -1;
  r0.w = VignetteParams * r0.w + 1;
  r0.xyz = r0.www * r0.xyz;
  
  // HDR tone mapping
  float3 hdr_color = ExpandToHDR(r0.xyz, peak_white_nits, diffuse_white_nits);
  
  // Apply gamma correction if enabled
  if (gamma_correction > 0.5)
  {
    // Rec. 2020 EOTF (inverse of 2.2)
    hdr_color = pow(max(float3(0, 0, 0), hdr_color), float3(1.0 / 2.4, 1.0 / 2.4, 1.0 / 2.4));
  }
  
  // Color grading LUT (applied in linear space)
  r1.xyz = hdr_color;
  r1.xyz = log2(r1.xyz);
  r1.xyz = float3(0.416666657, 0.416666657, 0.416666657) * r1.xyz;
  r1.xyz = exp2(r1.xyz);
  r1.xyz = r1.xyz * float3(1.05499995, 1.05499995, 1.05499995) + float3(-0.0549999997, -0.0549999997, -0.0549999997);
  r2.xyz = cmp(hdr_color < float3(0.00313080009, 0.00313080009, 0.00313080009));
  hdr_color = float3(12.9200001, 12.9200001, 12.9200001) * hdr_color;
  hdr_color = r2.xyz ? hdr_color : r1.xyz;
  hdr_color = saturate(hdr_color);
  hdr_color = hdr_color * float3(0.9375, 0.9375, 0.9375) + float3(0.03125, 0.03125, 0.03125);
  hdr_color = ColorGradingLUT.Sample(ColorGradingLUTSampler_s, hdr_color).xyz;
  
  o0.xyz = saturate(hdr_color);
  o0.w = 1;
  return;
}
