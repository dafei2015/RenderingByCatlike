#if !defined(MY_LIGHTING7_INCLUDED)
#define MY_LIGHTING7_INCLUDED
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"


float4 _Tint;
sampler2D _MainTex,_DetailTex;
float4 _MainTex_ST,_DetailTex_ST;
sampler2D _NormalMap,_DetailNormalMap;
float _BumpScale,_DetailBumpScale;
// sampler2D _HeightMap;
// float4 _HeightMap_TexelSize;
//float4 _SpecularTint;
float _Metallic;
float _Smoothness;

struct VertexData
{
    float4 vertex:POSITION;
    float3 normal:NORMAL;
    float4 tangent:TANGENT;
    float2 uv:TEXCOORD0;
};

float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
    return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
}
struct Interpolators
{
    float4 pos:SV_POSITION;
    // float2 uv:TEXCOORD0;
    float4 uv:TEXCOORD0;
    float3 normal:TEXCOORD1;
    
    #if defined(BINORMAL_PER_FRAGMENT)
    float4 tangent : TEXCOORD2;
    #else
    float3 tangent : TEXCOORD2;
    float3 binormal : TEXCOORD3;
    #endif

    float3 worldPos : TEXCOORD4;

    // #if defined(SHADOWS_SCREEN)
    // float4 shadowCoordinates : TEXCOORD5;
    // #endif
    SHADOW_COORDS(5)

    #if defined(VERTEXLIGHT_ON)
    float3 vertexLightColor : TEXCOORD6;
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
    i.pos = UnityObjectToClipPos(v.vertex);
    i.worldPos = mul(unity_ObjectToWorld, v.vertex);
    i.normal = UnityObjectToWorldNormal(v.normal);
    
    #if defined(BINORMAL_PER_FRAGMENT)
    i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
    #else
    i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
    i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
    #endif
    
    i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
    i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

    // #if defined(SHADOWS_SCREEN)
    // // i.shadowCoordinates.xy = (float2(i.position.x, -i.position.y) + i.position.w) * 0.5;
    // // i.shadowCoordinates.zw = i.position.zw;
    // i.shadowCoordinates = ComputeScreenPos(i.position);
    // #endif
    TRANSFER_SHADOW(i);
    
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
    // #if defined(SHADOWS_SCREEN)
    // // float attenuation = tex2D(
    // //     _ShadowMapTexture,
    // //     i.shadowCoordinates.xy / i.shadowCoordinates.w
    // // );
    // SHADOW_ATTENUATION(i);
    // #else
    UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
    // #endif
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

void InitializeFragmentNormal(inout Interpolators i)
{
    // //差分法
    // // float2 delta = float2(_HeightMap_TexelSize.x, 0);
    // // float h1 = tex2D(_HeightMap, i.uv);
    // // float h2 = tex2D(_HeightMap, i.uv + delta);
    //
    // //中心差分法
    // float2 du = float2(_HeightMap_TexelSize.x*0.5, 0);
    // float u1 = tex2D(_HeightMap, i.uv - du);
    // float u2 = tex2D(_HeightMap, i.uv + du);
    // // float3 tu = float3( 1, u2 - u1, 0); //切线
    // // i.normal = float3(u1-u2,1,0);//法线，将x,y调换然后将x的值取反
    //
    // //中心差分法
    // float2 dv = float2(_HeightMap_TexelSize.y*0.5, 0);
    // float v1 = tex2D(_HeightMap, i.uv - dv);
    // float v2 = tex2D(_HeightMap, i.uv + dv);
    // // float3 tv = float3( 0, v2 - v1, 1); //切线
    // // i.normal = float3(0,1,v1-v2);//法线，将x,y调换然后将x的值取反
    //
    // // i.normal = cross(tv,tu); //使用右手定则确定方向，所以使用tv*tu  https://zhuanlan.zhihu.com/p/359975221
    // i.normal = float3(u1-u2,1,v1-v2);

    // //对法线贴图解码 DXT5nm压缩
    // i.normal.xy = tex2D(_NormalMap,i.uv).wy *2 -1;
    // i.normal.xy *= _BumpScale;
    // i.normal.z = sqrt(1- saturate(dot(i.normal.xy,i.normal.xy)));

    //使用Unity UnpackScaleNormal函数解码法线
    float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap,i.uv.xy),_BumpScale);
    float3 detailNormal = UnpackScaleNormal(tex2D(_NormalMap,i.uv.zw),_DetailBumpScale);
    // i.normal = float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1);
    // i.normal = float3(mainNormal.xy  + detailNormal.xy , mainNormal.z*detailNormal.z);
    float3 tangentSpaceNormal = BlendNormals(mainNormal,detailNormal);
    tangentSpaceNormal = tangentSpaceNormal.xzy;
    // float3 binormal = cross(i.normal,i.tangent.xyz) * i.tangent.w;
    #if defined(BINORMAL_PER_FRAGMENT)
        float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
    #else
        float3 binormal = i.binormal;
    #endif
    //法线从切线空间转换成世界空间。
    i.normal = normalize(
     tangentSpaceNormal.x * i.tangent +
     tangentSpaceNormal.y * i.normal +
     tangentSpaceNormal.z * binormal );
    // i.normal = normalize(i.normal);
}

//PBS 基于物理的着色
float4 MyFragmentProgram(Interpolators i):SV_TARGET
{
    InitializeFragmentNormal(i);
 
    float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);

    float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Tint.rgb;
    albedo *= tex2D(_DetailTex,i.uv.zw)*unity_ColorSpaceDouble;
    // albedo *=tex2D(_HeightMap,i.uv);
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

