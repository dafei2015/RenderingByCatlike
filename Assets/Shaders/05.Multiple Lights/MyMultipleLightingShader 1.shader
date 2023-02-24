// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My Multiple Lighting Shader"
{
    Properties
    {
        _Tint("Tint",Color) = (1,1,1,1)
        _MainTex("Albedo",2D) = "white"{}
//        _SpecularTint ("Specular", Color) = (0.5, 0.5, 0.5)
        [Gamma]_Metallic("Metallic",Range(0,1)) = 0
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
    }
    SubShader
    {
        pass
        {
            Tags{ "LightMode" = "ForwardBase"}
            CGPROGRAM

            #pragma target 3.0

            #pragma multi_compile _ VERTEXLIGHT_ON

            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            #define FORWARD_BASE_PASS
            #include "My Lighting.cginc"
            
            ENDCG
        }
        
         pass
        {
            Tags{ "LightMode" = "ForwardAdd"}
            
            Blend One One
            Zwrite Off
            CGPROGRAM

            #pragma target 3.0
            #pragma multi_compile_fwdadd
            // #pragma multi_compile DIRECTIONAL DIRECTIONAL_COOKIE POINT SPOT
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram

            // #define POINT;
            #include "My Lighting.cginc"
            
            ENDCG
        }
    }
}
