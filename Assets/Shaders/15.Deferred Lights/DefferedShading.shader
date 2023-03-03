Shader "Custom/DefferedShading"
{
    Properties
    {
        
    }
    SubShader
    {
        Pass
        {
            Blend one one
//            Cull Off
//            ZTest Always
            ZWrite Off
            
            Blend [_SrcBlend] [_DstBlend]
            Stencil
            {
                Ref [_StencilNonBackground]
                ReadMask [_StencilNonBackground]
                CompBack Equal
                CompFront Equal
            }
            CGPROGRAM

            #pragma target 3.0
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

            #pragma exclude_renderers nomrt

            //为所有可能的光线配置着色变种。 multi_compile_lightpass 编译器指令创建我们需要的所有关键字组合。唯一的例外是 HDR 模式。我们必须为此添加一个单独的多编译指令。
            #pragma multi_compile_lightpass
			#pragma multi_compile _ UNITY_HDR_ON

            #include "DeferredShading.cginc"
            ENDCG
        }
        
         Pass
        {
            Cull Off
            ZTest Always
            ZWrite Off
            
           
            CGPROGRAM

            #pragma target 3.0
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

            #pragma exclude_renderers nomrt 

            #include "UnityCG.cginc"

             sampler2D _LightBuffer; //_ LightBuffer 变量，光缓冲区本身对着色器是可用的。
            
            struct VertexData
            {
                float4 vertex : POSITION;
                float2 uv:TEXCOORD0;
            };

            struct Interpolators
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
            };

            Interpolators VertexProgram(VertexData v)
            {
                Interpolators i;
                i.pos = UnityObjectToClipPos(v.vertex);
                i.uv = v.uv;
                return i;
            }

            float4 FragmentProgram(Interpolators i):SV_TARGET
            {
                //LDR 颜色是对数编码的，使用公式2-C。要解码这个，我们必须使用公式 -log2 C。
                float4 color = -log2(tex2D(_LightBuffer,i.uv));
                return color;
            }
            ENDCG
        }
    }
}
