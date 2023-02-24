// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
//BRDF 表示双向反射分布函数
Shader "Custom/My First Lighting Shader"
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
            #pragma vertex MyVertexProgram
            #pragma fragment MyFragmentProgram
            
            // #include "UnityCG.cginc"
            // #include "UnityStandardBRDF.cginc"
            // #include "UnityStandardUtils.cginc"
            #include "UnityPBSLighting.cginc"

            float4 _Tint;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            //float4 _SpecularTint;
            float _Metallic;
            float _Smoothness;

            struct VertexData
            {
                float4 position:POSITION;
                float3 normal:NORMAL;
                float2 uv:TEXCOORD0;
            };
            
            struct Interpolators
            {
                float4 position:SV_POSITION;
                float2 uv:TEXCOORD0;
                float3 normal:TEXCOORD1;
                float3 worldPos:TEXCOORD2;
            };

          
            Interpolators MyVertexProgram(VertexData v)
            {
                Interpolators i;
                // i.localPosition = v.position.xyz;
                i.position = UnityObjectToClipPos(v.position);
                i.worldPos = mul(unity_ObjectToWorld,v.position);
                i.normal = UnityObjectToWorldNormal(v.normal);
                i.uv = TRANSFORM_TEX(v.uv,_MainTex);
                // i.normal =mul(transpose((float3x3)unity_WorldToObject),v.normal);
                //
                // i.normal = normalize(i.normal);
                return i;
            }

            // //Specula 镜面发射
            // float4 MyFragmentProgram(Interpolators i):SV_TARGET
            // {
            //      i.normal = normalize(i.normal);
            //     float3 lightDir = _WorldSpaceLightPos0.xyz;
            //     float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
            //     float3 lightColor = _LightColor0.rgb;
            //     float3 albedo = tex2D(_MainTex,i.uv).rgb *_Tint.rgb;
            //     //albedo *= 1-max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
            //
            //     float oneMinusReflectivity;
            //     //EnergyConservationBetweenDiffuseAndSpecular以反射率和高光颜色作为输入，并输出一个调整后的反射率。但它也有第三个输出参数，称为1-减反射率。
            //     albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo,_SpecularTint.rgb,oneMinusReflectivity);
            //     //漫反射
            //     float3 diffuse = albedo * lightColor * DotClamped(lightDir,i.normal);
            //
            //     // Blinn 反射模型计算反射
            //     // float3 reflectionDir = reflect(-lightDir,i.normal);
            //     // return  pow(DotClamped(viewDir,reflectionDir),_Smoothness*100);
            //
            //     //最常用的模型是 Blinn-Phong。它使用一个介于光线方向和视图方向之间的矢量。法向量和半向量之间的点积决定了镜面反射。
            //     float3 halfVector = normalize(lightDir + viewDir);
            //     //镜面发射
            //     float3 specular =_SpecularTint.rgb * lightColor * pow(DotClamped(halfVector,i.normal),_Smoothness *100);
            //     return float4(diffuse + specular,1);
            // }

            
            // //Metallic 金属反射
            // float4 MyFragmentProgram(Interpolators i):SV_TARGET
            // {
            //      i.normal = normalize(i.normal);
            //     float3 lightDir = _WorldSpaceLightPos0.xyz;
            //     float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
            //     float3 lightColor = _LightColor0.rgb;
            //     float3 albedo = tex2D(_MainTex,i.uv).rgb *_Tint.rgb;
            //     //albedo *= 1-max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));
            //
            //     float3 specularTint ;
            //     
            //     float oneMinusReflectivity ;
            //     //EnergyConservationBetweenDiffuseAndSpecular以反射率和高光颜色作为输入，并输出一个调整后的反射率。但它也有第三个输出参数，称为1-减反射率。
            //     // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo,_SpecularTint.rgb,oneMinusReflectivity);
            //     //漫反射
            //     albedo = DiffuseAndSpecularFromMetallic(albedo,_Metallic,specularTint,oneMinusReflectivity);
            //     float3 diffuse = albedo * lightColor * DotClamped(lightDir,i.normal);
            //
            //     // Blinn 反射模型计算反射
            //     // float3 reflectionDir = reflect(-lightDir,i.normal);
            //     // return  pow(DotClamped(viewDir,reflectionDir),_Smoothness*100);
            //
            //     //最常用的模型是 Blinn-Phong。它使用一个介于光线方向和视图方向之间的矢量。法向量和半向量之间的点积决定了镜面反射。
            //     float3 halfVector = normalize(lightDir + viewDir);
            //     //镜面发射
            //     float3 specular =specularTint.rgb * lightColor * pow(DotClamped(halfVector,i.normal),_Smoothness *100);
            //     return float4(diffuse + specular,1);
            // }

              //PBS 基于物理的着色
            float4 MyFragmentProgram(Interpolators i):SV_TARGET
            {
                 i.normal = normalize(i.normal);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 lightColor = _LightColor0.rgb;
                float3 albedo = tex2D(_MainTex,i.uv).rgb *_Tint.rgb;
                //albedo *= 1-max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));

                float3 specularTint ;
                
                float oneMinusReflectivity ;
                //EnergyConservationBetweenDiffuseAndSpecular以反射率和高光颜色作为输入，并输出一个调整后的反射率。但它也有第三个输出参数，称为1-减反射率。
                // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo,_SpecularTint.rgb,oneMinusReflectivity);
                //漫反射
                albedo = DiffuseAndSpecularFromMetallic(albedo,_Metallic,specularTint,oneMinusReflectivity);
                // float3 diffuse = albedo * lightColor * DotClamped(lightDir,i.normal);
                //
                // // Blinn 反射模型计算反射
                // // float3 reflectionDir = reflect(-lightDir,i.normal);
                // // return  pow(DotClamped(viewDir,reflectionDir),_Smoothness*100);
                //
                // //最常用的模型是 Blinn-Phong。它使用一个介于光线方向和视图方向之间的矢量。法向量和半向量之间的点积决定了镜面反射。
                // float3 halfVector = normalize(lightDir + viewDir);
                // //镜面发射
                // float3 specular =specularTint.rgb * lightColor * pow(DotClamped(halfVector,i.normal),_Smoothness *100);
                UnityLight unity_light;
                unity_light.color = lightColor;
                unity_light.dir = lightDir;
                unity_light.ndotl = DotClamped(i.normal,lightDir);
                
                UnityIndirect unity_indirect;
                unity_indirect.diffuse = 0;
                unity_indirect.specular = 0;
                
                return UNITY_BRDF_PBS(
					albedo, specularTint,
					oneMinusReflectivity, _Smoothness,
					i.normal, viewDir,unity_light,unity_indirect);
            }
            ENDCG
        }
    }
}
