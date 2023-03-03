// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#if !defined(MY_LIGHTMAPPING_INCLUDED)
    #define MY_LIGHTMAPPING_INCLUDED
    #include "UnityPBSLighting.cginc"
    #include "UnityMetaPass.cginc"

    float4 _Color;
    sampler2D _MainTex,_DetailTex,_DetailMask;
    float4 _MainTex_ST,_DetailTex_ST;
    
    sampler2D _MetallicMap;
    float _Metallic;
    float _Smoothness;

    sampler2D _EmissionMap;
    float3 _Emission;

    struct VertexData
    {
        float4 vertex:POSITION;
        float2 uv:TEXCOORD0;
        float2 uv1:TEXCOORD1;  //采样光照图的坐标存储在第二纹理坐标通道 uv1
    };

    struct Interpolators
    {
        float4 pos:SV_POSITION;
        float4 uv:TEXCOORD0;
    };

    float GetDetailMask(Interpolators i)
    {
        #if defined(_DETAIL_MASK)
            return tex2D(_DetailMask,i.uv.xy).a;
        #else
            return 1;
        #endif
    }

    float3 GetAlbedo(Interpolators i)
    {
        float3 albedo = tex2D(_MainTex, i.uv.xy).rgb * _Color.rgb;
        #if defined (_DETAIL_ALBEDO_MAP)
            float3 details = tex2D(_DetailTex, i.uv.zw) * unity_ColorSpaceDouble;
            albedo = lerp(albedo, albedo * details, GetDetailMask(i));
        #endif
        return albedo;
    }

    float GetMetallic(Interpolators i)
    {
        #if defined(_METALLIC_MAP)
            return tex2D(_MetallicMap, i.uv.xy).r;
        #else
            return _Metallic;
        #endif
    }

    float GetSmoothness(Interpolators i)
    {
        float smoothness = 1;
        #if defined(_SMOOTHNESS_ALBEDO)
            smoothness = tex2D(_MainTex, i.uv.xy).a;
        #elif defined(_SMOOTHNESS_METALLIC) && defined(_METALLIC_MAP)
            smoothness = tex2D(_MetallicMap, i.uv.xy).a;
        #endif
        return smoothness * _Smoothness;
    }
    float3 GetEmission (Interpolators i)
    {
        #if defined(_EMISSION_MAP)
            return tex2D(_EmissionMap, i.uv.xy) * _Emission;
        #else
            return _Emission;
        #endif              
    }
    Interpolators MyLightmappingVertexProgram(VertexData v)
    {
        Interpolators i;
        //我们实际上并不是为照相机渲染，而是为光照映射器渲染。
        //我们将颜色与物体的纹理在光照贴图中展开联系起来。
        //要执行这个映射，我们必须使用光照贴图坐标代替顶点位置，并进行适当的转换。
        v.vertex.xy = v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
        v.vertex.z = v.vertex.z >0 ?0.0001:0;
        // i.pos = UnityObjectToClipPos(v.vertex);  //在Unity5.6上可以使用
        i.pos = mul(UNITY_MATRIX_VP, float4(v.vertex.xyz, 1.0));  //在Unity2022.2.5上可以正常使用
                
        i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);
        return i;
    }


    float4 MyLightmappingFragmentProgram(Interpolators i):SV_TARGET
    {
        UnityMetaInput surfaceData;

        float oneMinusReflectivity;
        
        surfaceData.Albedo = DiffuseAndSpecularFromMetallic(GetAlbedo(i),GetMetallic(i),surfaceData.SpecularColor,oneMinusReflectivity);
        float roughness = SmoothnessToRoughness(GetSmoothness(i)) * 0.5;
        surfaceData.Albedo += surfaceData.SpecularColor * roughness;

        surfaceData.Emission = GetEmission(i);

        return UnityMetaFragment(surfaceData);
    }
#endif

