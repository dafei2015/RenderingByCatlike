// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My Deferred Shading Shader"
{
    
    Properties
    {
        _Tint("Tint",Color) = (1,1,1,1)
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
        
        _AlphaCutoff ("Alpha Cutoff",Range(0,1)) = 0.5
        
        [HideInInspector] _SrcBlend ("_SrcBlend", Float) = 1
		[HideInInspector] _DstBlend ("_DstBlend", Float) = 0
        [HideInInspector] _ZWrite ("_ZWrite", Float) = 1
    }
    CGINCLUDE

    #define BINORMAL_PER_FRAGMENT

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
            
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ VERTEXLIGHT_ON
            

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            #define FORWARD_BASE_PASS
             //#include "My Lighting3.cginc"
            #include "My Lighting7.cginc"
            
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

            #pragma multi_compile_fwdadd_fullshadows
            // #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            // #define POINT;
            #include "My Lighting7.cginc"
            
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

            #pragma multi_compile _ UNITY_HDR_ON

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            #define DEFERRED_PASS

            #include "My Lighting7.cginc"

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
            #pragma vertex MyShadowVertexProgram
            #pragma fragment MyShadowFragmentProgram
            
            // #define POINT;
            #include "../12.Semitransparent Shadows/My Shadows2.cginc"
            
            ENDCG
        }
        
    }
    
    CustomEditor "CustomShaderGUI"
}
