// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My Triplanar Mapping Shader"
{
    Properties 
	{
		_MainTex ("Albedo", 2D) = "white" {}
		[NoScaleOffset] _MOHSMap  ("MOHS", 2D) = "white" {}
		[NoScaleOffset] _NormalMap ("Normals", 2D) = "white" {}
		
		[NoScaleOffset] _TopMainTex ("Top Albedo", 2D) = "white" {}
		[NoScaleOffset] _TopMOHSMap ("Top MOHS", 2D) = "white" {}
		[NoScaleOffset] _TopNormalMap ("Top Normals", 2D) = "white" {}
		
		_MapScale ("Map Scale", Float) = 1
		_BlendOffset ("Blend Offset", Range(0, 0.5)) = 0.25
		_BlendExponent ("Blend Exponent", Range(1, 8)) = 2
		_BlendHeightStrength ("Blend Height Strength", Range(0, 0.99)) = 0.5
	}

	SubShader 
	{

		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardBase"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _SEPARATE_TOP_MAPS
			
			#pragma multi_compile_fwdbase
			#pragma multi_compile_fog
			#pragma multi_compile_instancing

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#define FORWARD_BASE_PASS

			#include "My TriplanarMapping.cginc"
			#include "My Lighting27.cginc"

			ENDCG
		}

		Pass 
		{
			Tags 
			{
				"LightMode" = "ForwardAdd"
			}

			Blend One One
			ZWrite Off

			CGPROGRAM

			#pragma target 3.0

			#pragma shader_feature _SEPARATE_TOP_MAPS
			
			#pragma multi_compile_fwdadd_fullshadows
			#pragma multi_compile_fog

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#include "My TriplanarMapping.cginc"
			#include "My Lighting27.cginc"

			ENDCG
		}
		
		Pass 
		{
			Tags 
			{
				"LightMode" = "Deferred"
			}

			CGPROGRAM

			#pragma target 3.0
			
			#pragma shader_feature _SEPARATE_TOP_MAPS

			#pragma exclude_renderers nomrt

			#pragma multi_compile_prepassfinal
			#pragma multi_compile_instancing

			#pragma vertex MyVertexProgram
			#pragma fragment MyFragmentProgram

			#define DEFERRED_PASS

			#include "My TriplanarMapping.cginc"
			#include "My Lighting27.cginc"

			ENDCG
		}

		Pass 
		{
			Tags 
			{
				"LightMode" = "ShadowCaster"
			}

			CGPROGRAM

			#pragma target 3.0

			#pragma multi_compile_shadowcaster
			#pragma multi_compile_instancing

			#pragma vertex MyShadowVertexProgram
			#pragma fragment MyShadowFragmentProgram

			#include "My Shadows27.cginc"

			ENDCG
		}
		
		Pass 
		{
			Tags 
			{
				"LightMode" = "Meta"
			}

			Cull Off

			CGPROGRAM

			#pragma vertex MyLightmappingVertexProgram
			#pragma fragment MyLightmappingFragmentProgram

			#pragma shader_feature _SEPARATE_TOP_MAPS

			#define META_PASS_NEEDS_NORMALS
			#define META_PASS_NEEDS_POSITION

			#include "My TriplanarMapping.cginc"
			#include "My Lightmapping27.cginc"

			ENDCG
		}
	}
	CustomEditor "CustomTriplanarShaderGUI"
}
