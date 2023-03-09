// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My Realtime GI And LOD Groups Shader"
{
    
    Properties
    {
        //Lightmapper 希望 alpha 截止值存储在 _ Cutoff 属性中，但是我们使用的是 _ AlphaCutoff
        //Lightmapper 使用的是_Color和_Cutoff 所以要更改命名
//        _Tint("Tint",Color) = (1,1,1,1)
        _Color("Tint",Color) = (1,1,1,1)
        _MainTex("Albedo",2D) = "white"{}
        //        _SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
        //        [NoScaleOffset] _HeightMap ("Heights", 2D) = "gray" {}
        [NoScaleOffset] _NormalMap ("Normals", 2D) = "bump" {}
        _BumpScale("Bump Scale",Float) =1
        
         [NoScaleOffset] _MetallicMap ("Metallic", 2D) = "white" {}
        [Gamma]_Metallic("Metallic",Range(0,1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        
        _DetailTex("Detail Albedo",2D) = "gray"{}
        [NoScaleOffset] _DetailNormalMap ("Detail Normals", 2D) = "bump" {}
        _DetailBumpScale ("Detail Bump Scale", Float) = 1
        
        [NoScaleOffset] _EmissionMap("Emission",2D) = "black"{}
        _Emission("Emission",Color) = (0,0,0)
        
        [NoScaleOffset] _OcclusionMap ("Occlusion", 2D) = "white" {}
		_OcclusionStrength("Occlusion Strength", Range(0, 1)) = 1
        
        [NoScaleOffset] _DetailMask ("Detail Mask", 2D) = "white" {}
        
//        _AlphaCutoff ("Alpha Cutoff",Range(0,1)) = 0.5
        _Cutoff ("Alpha Cutoff",Range(0,1)) = 0.5
        
        [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", Float) = 1
    }
    CGINCLUDE

    #define BINORMAL_PER_FRAGMENT
    #define FOG_DISTANCE
    
    ENDCG
    SubShader
    {
        pass
        {
            Tags{ "LightMode" = "ForwardBase"}
            Blend [_SrcBlend] [_DstBlend]
            ZWrite [_ZWrite]
            CGPROGRAM

            #pragma target 3.0
            // shader_feature与multi_compile非常相似。
            // 唯一的区别是Unity在最终的版本中不包括shader_feature着色器的未使用的变体。
            // 出于这个原因，你应该使用shader_feature来处理从material中设置的关键字，
            // 而multi_compile更好地处理从全局代码中设置的关键字。
            
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _OCCLUSION_MAP
            #pragma shader_feature _DETAIL_MASK
            #pragma shader_feature _EMISSION_MAP
            #pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

            #pragma multi_compile_fwdbase
            #pragma multi_compile_fog
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            // #pragma multi_compile _ SHADOWS_SCREEN

            //当使用光照贴图时，Unity 将永远不会包括顶点光。他们的关键词是互斥的。所以我们不需要同时使用 VERTEXLIGHT _ ON 和 LIGHTMAP _ ON 的变体。
            // #pragma multi_compile _ LIGHTMAP_ON VERTEXLIGHT_ON
            

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            #define FORWARD_BASE_PASS
             //#include "My Lighting3.cginc"
            #include "My Lighting18.cginc"
            
            ENDCG
        }
        
        pass
        {
            Tags{ "LightMode" = "ForwardAdd"}
            
            Blend [_SrcBlend]  One
            Zwrite Off
            CGPROGRAM

            #pragma target 3.0

            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
            #pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _NORMAL_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

            #pragma multi_compile_fog
            #pragma multi_compile_fwdadd_fullshadows
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            // #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            // #define POINT;
            #include "My Lighting18.cginc"
            
            ENDCG
        }
        
        Pass
        {
            Tags{"LightMode" = "Deferred"}
            
            CGPROGRAM

            #pragma target 3.0
            #pragma exclude_renderers nomrt //只有当图形处理器支持对多个渲染目标进行写操作时，延期着色才有可能实现
            // shader_feature与multi_compile非常相似。
            // 唯一的区别是Unity在最终的版本中不包括shader_feature着色器的未使用的变体。
            // 出于这个原因，你应该使用shader_feature来处理从material中设置的关键字，
            // 而multi_compile更好地处理从全局代码中设置的关键字。
            
            #pragma shader_feature _ _RENDERING_CUTOUT
            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _NORMAL_MAP
            #pragma shader_feature _OCCLUSION_MAP
            #pragma shader_feature _DETAIL_MASK
            #pragma shader_feature _EMISSION_MAP
            #pragma shader_feature _DETAIL_ALBEDO_MAP
			#pragma shader_feature _DETAIL_NORMAL_MAP

            // #pragma multi_compile _ UNITY_HDR_ON
            // #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_prepassfinal
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            #define DEFERRED_PASS

            #include "My Lighting18.cginc"

            ENDCG
        }
//        
        Pass
        {
            Tags{ "LightMode" = "ShadowCaster"}
            
            
            CGPROGRAM
            
            #pragma target 3.0

            #pragma shader_feature _SEMITRANSPARENT_SHADOWS
            #pragma shader_feature _ _RENDERING_CUTOUT _RENDERING_FADE _RENDERING_TRANSPARENT
			#pragma shader_feature _SMOOTHNESS_ALBEDO
            
            #pragma multi_compile_shadowcaster
            #pragma multi_compile _ LOD_FADE_CROSSFADE
            
            #pragma vertex MyShadowVertexProgram
            #pragma fragment MyShadowFragmentProgram
            
            // #define POINT;
            #include "My Shadows18.cginc"
            
            ENDCG
        }
        
        Pass
        {
            Tags{ "LightMode" = "Meta"}  // 用于产生反照率和发射值的着色器通道，用作光映射的输入。
            
            Cull off
            
            CGPROGRAM
            
            #pragma vertex MyLightmappingVertexProgram
            #pragma fragment MyLightmappingFragmentProgram

            #pragma shader_feature _METALLIC_MAP
			#pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
			#pragma shader_feature _EMISSION_MAP
			#pragma shader_feature _DETAIL_MASK
			#pragma shader_feature _DETAIL_ALBEDO_MAP
            // #define POINT;
            #include "My Lightmapping18.cginc"
            
            ENDCG
        }
        
    }
    
    CustomEditor "CustomShaderGUI18"
}
