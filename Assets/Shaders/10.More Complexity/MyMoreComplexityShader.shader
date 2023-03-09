// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My More Complexity Shader"
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
    }
    CGINCLUDE

    #define BINORMAL_PER_FRAGMENT

    ENDCG
    SubShader
    {
        pass
        {
            Tags{ "LightMode" = "ForwardBase"}
            CGPROGRAM

            #pragma target 3.0
            // shader_feature与multi_compile非常相似。
            // 唯一的区别是Unity在最终的版本中不包括shader_feature着色器的未使用的变体。
            // 出于这个原因，你应该使用shader_feature来处理从material中设置的关键字，
            // 而multi_compile更好地处理从全局代码中设置的关键字。
            
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
            #include "My Lighting10.cginc"
            
            ENDCG
        }
        
        pass
        {
            Tags{ "LightMode" = "ForwardAdd"}
            
            Blend One One
            Zwrite Off
            CGPROGRAM

            #pragma target 3.0
            
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
            //#include "My Lighting3.cginc"
             #include "My Lighting10.cginc"
            
            ENDCG
        }
        pass
        {
            Tags{ "LightMode" = "ShadowCaster"}
            
            
            CGPROGRAM
            
            #pragma target 3.0

            #pragma multi_compile_shadowcaster
            #pragma vertex MyShadowVertexProgram
            #pragma fragment MyShadowFragmentProgram
            
            // #define POINT;
            #include "../07.Shadows/My Shadows7.cginc"
            
            ENDCG
        }
        
    }
    
    CustomEditor "CustomShaderGUI10"
}
