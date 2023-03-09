#if !defined(DEFERRED_SHADING17)
#define DEFERRED_SHADING17

#include "UnityPBSLighting.cginc"

sampler2D _CameraGBufferTexture0;
sampler2D _CameraGBufferTexture1;
sampler2D _CameraGBufferTexture2;
sampler2D _CameraGBufferTexture4;

float4 _LightColor,_LightDir;
float4 _LightPos; //没有方向性的灯有一个位置，可以通过 LightPos 获得。

float _LightAsQuad;//_ LightAsQuad 变量告诉我们处理的方向光还是其他光

#if defined(SHADOWS_SCREEN)
    sampler2D _ShadowMapTexture;
#endif

#if defined(POINT_COOKIE)
    samplerCUBE _LightTexture0;  //点光源的cookie是cube格式
#else
    sampler2D _LightTexture0;  //获取cookie纹理
#endif

sampler2D _LightTextureB0; //存储聚光灯的衰减信息
float4x4 unity_WorldToLight; 

UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
struct VertexData
{
    float4 vertex : POSITION;
    float3 normal:NORMAL;
};

struct Interpolators
{
    float4 pos:SV_POSITION;
    float4 uv:TEXCOORD0;
    float3 ray:TEXCOORD1;
};

Interpolators VertexProgram(VertexData v)
{
    Interpolators i;
    i.pos = UnityObjectToClipPos(v.vertex);
    i.uv = ComputeScreenPos(i.pos);
    i.ray = lerp(UnityObjectToViewPos(v.vertex) * float3(-1,-1,1),v.normal,_LightAsQuad);
    return i;
}

float GetShadowMaskAttenuation (float2 uv)
{
    float attenuation = 1;
    #if defined (SHADOWS_SHADOWMASK)
        float4 mask = tex2D(_CameraGBufferTexture4, uv);
        attenuation = saturate(dot(mask, unity_OcclusionMaskSelector));
    #endif
    return attenuation;
}

UnityLight CreatLight(float2 uv,float3 worldPos,float viewZ)
{
    UnityLight light;
    // light.dir = -_LightDir; //_ LightDir 被设置为光传播的方向。对于我们的计算，我们需要从表面到光的方向，所以相反。

    float attenuation =1;
    float shadowAttenuation = 1;
    bool shadowed = false;

    #if defined(DIRECTIONAL) || defined(DIRECTIONAL_COOKIE)
        light.dir = -_LightDir;
    
        #if defined(DIRECTIONAL_COOKIE)
            float2 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1)).xy;
            attenuation *= tex2Dbias(_LightTexture0, float4(uvCookie, 0, -8)).w;
        #endif
        
        #if defined(SHADOWS_SCREEN)
            shadowed = true;
            shadowAttenuation = tex2D(_ShadowMapTexture, uv).r;
           
        #endif
    #else
        float3 lightVec = _LightPos.xyz - worldPos;
        light.dir =normalize(lightVec);

        attenuation *= tex2D(_LightTextureB0,(dot(lightVec, lightVec) * _LightPos.w).rr).UNITY_ATTEN_CHANNEL;

        #if defined(SPOT)
            float4 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1));
            uvCookie.xy /= uvCookie.w;
            attenuation *= tex2Dbias(_LightTexture0, float4(uvCookie.xy, 0, -8)).w;
            attenuation *= uvCookie.w < 0;

            #if defined(SHADOWS_DEPTH)
                shadowed = true;
                //UnitySampleShadowmap 来处理采样硬阴影或软阴影的细节。
                //我们必须给它提供阴影空间中的碎片位置。Unity _ WorldToShadow 数组中的第一个矩阵可用于从世界转换为阴影空间。
                shadowAttenuation = UnitySampleShadowmap(mul(unity_WorldToShadow[0], float4(worldPos, 1)));
            #endif
        #else
            #if defined(POINT_COOKIE)
                float3 uvCookie = mul(unity_WorldToLight, float4(worldPos, 1)).xyz;
                attenuation *= texCUBEbias(_LightTexture0, float4(uvCookie, -8)).w;
            #endif
            #if defined(SHADOWS_CUBE)
                shadowed = true;
                //点光源的阴影存储在立方体地图中。UnitySampleShadowmap 为我们处理采样。
                //在这种情况下，我们必须为它提供一个从光到表面的矢量，以便对立方体映射进行取样。这是光向量的反面。
                shadowAttenuation = UnitySampleShadowmap(-lightVec);
            #endif
        #endif
    #endif
    
    #if defined(SHADOWS_SHADOWMASK)
        shadowed = true;
    #endif
    if(shadowed)
    {
        float shadowFadeDistance = UnityComputeShadowFadeDistance(worldPos,viewZ);
        float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
        shadowAttenuation = UnityMixRealtimeAndBakedShadows(shadowAttenuation,GetShadowMaskAttenuation(uv),shadowFade);

        #if defined(UNITY_FAST_COHERENT_DYNAMIC_BRANCHING) && defined(SHADOWS_SOFT)
            #if !defined(SHADOWS_SHADOWMASK)
                UNITY_BRANCH
                if(shadowFade >0.99)
                    shadowAttenuation =1;
            #endif
        #endif
    }

    light.color =_LightColor.rgb * (attenuation * shadowAttenuation);
    return light;
}

float4 FragmentProgram(Interpolators i):SV_TARGET
{
    float2 uv = i.uv.xy/i.uv.w;
    float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,uv);
    depth = Linear01Depth(depth);

    //i.ray/i.ray.z _ProjectParams.z 获得远平面的向量
    float3 rayToFarPlane = i.ray * _ProjectionParams.z /i.ray.z;
    float3 viewPos = rayToFarPlane * depth;

    //从相机坐标转换成世界坐标
    float3 worldPos = mul(unity_CameraToWorld,float4(viewPos,1)).xyz;
    float3 viewDir = normalize(_WorldSpaceCameraPos - worldPos);
    
    float3 albedo = tex2D(_CameraGBufferTexture0,uv).rgb;
    float3 specularTint = tex2D(_CameraGBufferTexture1,uv).rgb;
    float3 smoothness = tex2D(_CameraGBufferTexture1,uv).a;
    float3 normal = tex2D(_CameraGBufferTexture2,uv).rgb *2 -1;
    float oneMinusReflectivity = 1- SpecularStrength(specularTint);

    UnityLight light = CreatLight(uv,worldPos,viewPos.z);

    UnityIndirect indirectLight;
    indirectLight.diffuse =0;
    indirectLight.specular =0;

    float4 color = UNITY_BRDF_PBS(albedo,specularTint,oneMinusReflectivity,smoothness,normal,viewDir,light,indirectLight);
    #if !defined(UNITY_HDR_ON)
        color = exp2(-color);
    #endif
    return color;
}
#endif