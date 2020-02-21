#if UNITY_VERSION >= 201930
  #ifndef UNIVERSAL_META_PASS_INCLUDED
  #define UNIVERSAL_META_PASS_INCLUDED
  #endif

  #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
  #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
#else
  #ifndef LIGHTWEIGHT_META_PASS_INCLUDED
  #define LIGHTWEIGHT_META_PASS_INCLUDED
  #endif

  #include "Packages/com.unity.render-pipelines.lightweight/ShaderLibrary/Lighting.hlsl"
#endif

CBUFFER_START(UnityMetaPass)
// x = use uv1 as raster position
// y = use uv2 as raster position
bool4 unity_MetaVertexControl;

// x = return albedo
// y = return normal
bool4 unity_MetaFragmentControl;
CBUFFER_END

float unity_OneOverOutputBoost;
float unity_MaxOutputValue;
float unity_UseLinearSpace;

struct MetaInput
{
    half3 Albedo;
    half3 Emission;
    half3 SpecularColor;
};

#if UNITY_VERSION >= 201930
  struct Attributes
  {
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float2 uv0          : TEXCOORD0;
    float2 uv1          : TEXCOORD1;
    float2 uv2          : TEXCOORD2;
  #ifdef _TANGENT_TO_WORLD
    float4 tangentOS     : TANGENT;
  #endif
  };
#else
  struct Attributes
  {
    float4 positionOS   : POSITION;
    half3  normalOS     : NORMAL;
    float2 uv           : TEXCOORD0;
    float2 uvLM         : TEXCOORD1;
    float2 uvDLM        : TEXCOORD2;
  #ifdef _TANGENT_TO_WORLD
    half4 tangentOS     : TANGENT;
  #endif
  };
#endif

struct Varyings
{
    float4 positionCS   : SV_POSITION;
    float2 uv           : TEXCOORD0;
    float4 screenPos    : TEXCOORD1;
};

#if UNITY_VERSION >= 201930
  float4 MetaVertexPosition(float4 positionOS, float2 uv1, float2 uv2, float4 uv1ST, float4 uv2ST)
  {
    if (unity_MetaVertexControl.x)
    {
        positionOS.xy = uv1 * uv1ST.xy + uv1ST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        positionOS.z = positionOS.z > 0 ? REAL_MIN : 0.0f;
    }
    if (unity_MetaVertexControl.y)
    {
        positionOS.xy = uv2 * uv2ST.xy + uv2ST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        positionOS.z = positionOS.z > 0 ? REAL_MIN : 0.0f;
    }
    return TransformWorldToHClip(positionOS.xyz);
  }
#else
  float4 MetaVertexPosition(float4 positionOS, float2 uvLM, float2 uvDLM, float4 lightmapST)
  {
    if (unity_MetaVertexControl.x)
    {
        positionOS.xy = uvLM * lightmapST.xy + lightmapST.zw;
        // OpenGL right now needs to actually use incoming vertex position,
        // so use it in a very dummy way
        positionOS.z = positionOS.z > 0 ? REAL_MIN : 0.0f;
    }
    return TransformWorldToHClip(positionOS.xyz);
  }
#endif

half4 MetaFragment(MetaInput input)
{
    half4 res = 0;
    if (unity_MetaFragmentControl.x)
    {
        res = half4(input.Albedo, 1.0);

        // d3d9 shader compiler doesn't like NaNs and infinity.
        unity_OneOverOutputBoost = saturate(unity_OneOverOutputBoost);

        // Apply Albedo Boost from LightmapSettings.
        res.rgb = clamp(PositivePow(res.rgb, unity_OneOverOutputBoost), 0, unity_MaxOutputValue);
    }
    if (unity_MetaFragmentControl.y)
    {
#if UNITY_VERSION >= 201930
        half3 emission;
        if (unity_UseLinearSpace)
            emission = input.Emission;
        else
            emission = LinearToSRGB(input.Emission);

        res = half4(emission, 1.0);
#else
        res = half4(input.Emission, 1.0);
#endif
        
    }
    return res;
}

#if UNITY_VERSION < 201900 //todo: is it true?
Varyings LightweightVertexMeta(Attributes input)
{
    Varyings output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uvLM, input.uvDLM, unity_LightmapST);
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    return output;
}
#endif
Varyings UniversalVertexMeta(Attributes input)
{
    Varyings output;
    output.positionCS = MetaVertexPosition(input.positionOS, input.uvLM, input.uvDLM, unity_LightmapST);
    #if UNITY_VERSION < 201900
    output.uv = TRANSFORM_TEX(input.uv, _MainTex);
    #else
    output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
    #endif
    return output;
}

