// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My Complex Shader"
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

            #pragma shader_feature _METALLIC_MAP
            #pragma shader_feature _ _SMOOTHNESS_ALBEDO _SMOOTHNESS_METALLIC
            #pragma shader_feature _EMISSION_MAP
            #pragma multi_compile _ SHADOWS_SCREEN
            #pragma multi_compile _ VERTEXLIGHT_ON

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            #define FORWARD_BASE_PASS
             //#include "My Lighting3.cginc"
            #include "My Lighting9.cginc"
            
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
            #pragma multi_compile_fwdadd_fullshadows
            // #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            // #define POINT;
            //#include "My Lighting3.cginc"
             #include "My Lighting9.cginc"
            
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
    
    CustomEditor "CustomShaderGUI9"
}
