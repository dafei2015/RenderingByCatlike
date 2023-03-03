Shader "Custom/MyDeferredFogShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Cull Off
        ZTest Always
        ZWrite Off
        
        Pass
        {
            CGPROGRAM
            
            #pragma vertex VertexProgram
            #pragma fragment FragmentProgram

            #pragma multi_compile_fog
            #define FOG_DISTANCE
            // #define FOG_SKYBOX

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _CameraDepthTexture;  //Unity 通过 _ CameraDepthTexture 变量使深度缓冲区可用

            float3 _FrustumCorners[4];
            struct VertexData
            {
                float4 vertex:POSITION;
                float2 uv:TEXCOORD0;
            };

            struct Interpolators
            {
                float4 pos:SV_POSITION;
                float2 uv:TEXCOORD0;
                #if defined(FOG_DISTANCE)
					float3 ray : TEXCOORD1;
				#endif
            };

            Interpolators VertexProgram(VertexData v)
            {
                Interpolators i;
                i.pos = UnityObjectToClipPos(v.vertex);
                i.uv = v.uv;
                //在顶点程序中，我们可以简单地使用uv坐标来访问角点数组。坐标是(0,0)、(1,0)、(0,1)和(1,1)。所以索引是u+2v
                #if defined(FOG_DISTANCE)
					i.ray = _FrustumCorners[v.uv.x + 2 * v.uv.y];
				#endif
                return i;
            }

            float4 FragmentProgram(Interpolators i):SV_Target
            {
                //获取深度缓冲区，确切的语法取决于目标平台。在 HLSLSupport 中定义的 SAMPLE _ DEPTH _ TEXTURE 宏为我们处理这个问题
                float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture,i.uv);
                depth = Linear01Depth(depth);
                float viewDistance= depth * _ProjectionParams.z - _ProjectionParams.y;

                #if defined(FOG_DISTANCE)
					viewDistance = length(i.ray * depth);
				#endif

                UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
                unityFogFactor = saturate(unityFogFactor);

                //当深度值接近1时，我们已经到达了远平面。如果我们不想雾化的天空盒，我们可以通过设置雾因子为1
                #if !defined(FOG_SKYBOX)
					if (depth > 0.9999)
					{
						unityFogFactor = 1;
					}
				#endif
                // 当没有定义雾关键字时，也可以通过强制雾因子为1来实现。这将使我们的着色器变成一个纹理复制操作，所以实际上最好是停用或删除雾组件，如果你不需要它。
                #if !defined(FOG_LINEAR) && !defined(FOG_EXP) && !defined(FOG_EXP2)
					unityFogFactor = 1;
				#endif
                float3 sourceColor = tex2D(_MainTex,i.uv).rgb;

                float3 foggedColor = lerp(unity_FogColor.rgb,sourceColor,unityFogFactor);
                return float4(foggedColor,1);
            }
                
            ENDCG
        }
    }
}
