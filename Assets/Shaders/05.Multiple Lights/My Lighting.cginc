#if !defined(MY_LIGHTING_INCLUDED)
#define MY_LIGHTING_INCLUDED
#include "AutoLight.cginc"
#include "UnityPBSLighting.cginc"

float4 _Tint;
sampler2D _MainTex;
float4 _MainTex_ST;
//float4 _SpecularTint;
float _Metallic;
float _Smoothness;

struct VertexData
{
    float4 position:POSITION;
    float3 normal:NORMAL;
    float2 uv:TEXCOORD0;
};

struct Interpolators
{
    float4 position:SV_POSITION;
    float2 uv:TEXCOORD0;
    float3 normal:TEXCOORD1;
    float3 worldPos:TEXCOORD2;

    #if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor : TEXCOORD3;
    #endif
};

void ComputeVertexLightColor(inout Interpolators i)
{
    #if defined(VERTEXLIGHT_ON)
    float3 lightPos = float3(
        unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
    );

    float3 lightVec = lightPos - i.worldPos;
    float3 lightDir = normalize(lightVec);
    float ndotl = DotClamped(i.normal,lightDir);
    float attenuation = 1/(1+dot(lightVec,lightVec)*unity_4LightAtten0);
    i.vertexLightColor = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
        unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
        unity_4LightAtten0,i.worldPos,i.normal);
    #endif
}

Interpolators MyVertexProgram(VertexData v)
{
    Interpolators i;
    // i.localPosition = v.position.xyz;
    i.position = UnityObjectToClipPos(v.position);
    i.worldPos = mul(unity_ObjectToWorld, v.position);
    i.normal = UnityObjectToWorldNormal(v.normal);
    i.uv = TRANSFORM_TEX(v.uv, _MainTex);
    ComputeVertexLightColor(i);
    // i.normal =mul(transpose((float3x3)unity_WorldToObject),v.normal);
    //
    // i.normal = normalize(i.normal);
    return i;
}

UnityLight CreateLight(Interpolators i)
{
    UnityLight light;
    #if defined(POINT) ||   defined(POINT_COOKIE) ||defined(SPOT)
    light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
    #else
    light.dir = _WorldSpaceLightPos0.xyz;
    #endif
    // float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
    // float attenuation = 1/(1+dot(lightVec,lightVec));
    UNITY_LIGHT_ATTENUATION(attenuation,0,i.worldPos)
    light.color = _LightColor0.rgb * attenuation;
    light.ndotl = DotClamped(i.normal,light.dir);
    return light;
}

UnityIndirect CreatIndirectLight(Interpolators i)
{
    UnityIndirect indirectLight;
    indirectLight.diffuse =0;
    indirectLight.specular =0;
    
    #if defined(VERTEXLIGHT_ON)
    indirectLight.diffuse = i.vertexLightColor;
    #endif

    #if defined(FORWARD_BASE_PASS)
    indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
    #endif
    return indirectLight;
}

//PBS 基于物理的着色
float4 MyFragmentProgram(Interpolators i):SV_TARGET
{
    i.normal = normalize(i.normal);
 
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 albedo = tex2D(_MainTex, i.uv).rgb * _Tint.rgb;
    //albedo *= 1-max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));

    float3 specularTint;

    float oneMinusReflectivity;
    //EnergyConservationBetweenDiffuseAndSpecular以反射率和高光颜色作为输入，并输出一个调整后的反射率。但它也有第三个输出参数，称为1-减反射率。
    // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo,_SpecularTint.rgb,oneMinusReflectivity);
    //漫反射
    albedo = DiffuseAndSpecularFromMetallic(albedo, _Metallic, specularTint, oneMinusReflectivity);
    // float3 diffuse = albedo * lightColor * DotClamped(lightDir,i.normal);
    //
    // // Blinn 反射模型计算反射
    // // float3 reflectionDir = reflect(-lightDir,i.normal);
    // // return  pow(DotClamped(viewDir,reflectionDir),_Smoothness*100);
    //
    // //最常用的模型是 Blinn-Phong。它使用一个介于光线方向和视图方向之间的矢量。法向量和半向量之间的点积决定了镜面反射。
    // float3 halfVector = normalize(lightDir + viewDir);
    // //镜面发射
    // float3 specular =specularTint.rgb * lightColor * pow(DotClamped(halfVector,i.normal),_Smoothness *100);
    UnityLight unity_light = CreateLight(i);
    
    UnityIndirect unity_indirect = CreatIndirectLight(i);
    
    return UNITY_BRDF_PBS(
        albedo, specularTint,
        oneMinusReflectivity, _Smoothness,
        i.normal, viewDir, unity_light, unity_indirect);
}
#endif

