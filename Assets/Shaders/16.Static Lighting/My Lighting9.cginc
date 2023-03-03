// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#if !defined(MY_LIGHTING9_INCLUDED)
    #define MY_LIGHTING9_INCLUDED
    #include "UnityPBSLighting.cginc"
    #include "AutoLight.cginc"

    #if defined(FOG_LINEAR) || defined(FOG_EXP) || defined(FOG_EXP2)
        #if !defined(FOG_DISTANCE)
            #define FOG_DEPTH 1
        #endif
        #define FOG_ON 1
    #endif

    float4 _Color;
    sampler2D _MainTex,_DetailTex,_DetailMask;
    float4 _MainTex_ST,_DetailTex_ST;
    sampler2D _NormalMap,_DetailNormalMap;
    float _BumpScale,_DetailBumpScale;
    // sampler2D _HeightMap;
    // float4 _HeightMap_TexelSize;
    //float4 _SpecularTint;
    sampler2D _MetallicMap;
    float _Metallic;
    float _Smoothness;

    sampler2D _EmissionMap;
    float3 _Emission;

    sampler2D _OcclusionMap;
    float _OcclusionStrength;

    float _Cutoff;

    struct VertexData
    {
        float4 vertex:POSITION;
        float3 normal:NORMAL;
        float4 tangent:TANGENT;
        float2 uv:TEXCOORD0;
        float2 uv1:TEXCOORD1;  //采样光照图的坐标存储在第二纹理坐标通道 uv1
    };

    float3 CreateBinormal (float3 normal, float3 tangent, float binormalSign) {
        return cross(normal, tangent.xyz) * (binormalSign * unity_WorldTransformParams.w);
    }
    struct Interpolators
    {
        float4 pos:SV_POSITION;
        // float2 uv:TEXCOORD0;
        float4 uv:TEXCOORD0;
        float3 normal:TEXCOORD1;
        
        #if defined(BINORMAL_PER_FRAGMENT)
            float4 tangent : TEXCOORD2;
        #else
            float3 tangent : TEXCOORD2;
            float3 binormal : TEXCOORD3;
        #endif

        #if FOG_DEPTH
            float4 worldPos : TEXCOORD4;
        #else
            float3 worldPos : TEXCOORD4;
        #endif

        // #if defined(SHADOWS_SCREEN)
        // float4 shadowCoordinates : TEXCOORD5;
        // #endif
        SHADOW_COORDS(5)

        #if defined(VERTEXLIGHT_ON)
            float3 vertexLightColor : TEXCOORD6;
        #endif

        #if defined(LIGHTMAP_ON)
            float2 lightmapUV : TEXCOORD6;
        #endif
    };

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
        #if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
            #if defined(_EMISSION_MAP)
                return tex2D(_EmissionMap, i.uv.xy) * _Emission;
            #else
                return _Emission;
            #endif
        #else
            return 0;
        #endif
    }

    float GetOcclusion(Interpolators i)
    {
        #if defined(_OCCLUSION_MAP)
            return lerp(1, tex2D(_OcclusionMap, i.uv.xy).g, _OcclusionStrength);
        #else
            return 1;
        #endif
    }

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

    float3 GetTangentSpaceNormal (Interpolators i)
    {
        float3 normal = float3(0, 0, 1);
        #if defined(_NORMAL_MAP)
        normal = UnpackScaleNormal(tex2D(_NormalMap, i.uv.xy), _BumpScale);
        #endif
        #if defined(_DETAIL_NORMAL_MAP)
        float3 detailNormal =
            UnpackScaleNormal(
                tex2D(_DetailNormalMap, i.uv.zw), _DetailBumpScale
            );
        detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(i));
        normal = BlendNormals(normal, detailNormal);
        #endif
        return normal;
    }

    float GetAlpha(Interpolators i)
    {
        float alpha = _Color.a;
        #if !defined(_SMOOTHNESS_ALBEDO)
            alpha *= tex2D(_MainTex, i.uv.xy).a;
        #endif
        return alpha;
    }

    void ComputeVertexLightColor(inout Interpolators i)
    {
        #if defined(VERTEXLIGHT_ON)
            float3 lightPos = float3(
            unity_4LightPosX0.x, unity_4LightPosY0.x, unity_4LightPosZ0.x
            );

            float3 lightVec = lightPos - i.worldPos;
            float3 lightDir = normalize(lightVec);
            float ndotl = DotClamped(i.normal,lightDir);
            float attenuation = 1/(1+dot(lightVec,lightVec)*unity_4LightAtten0);
            i.vertexLightColor = Shade4PointLights(unity_4LightPosX0,unity_4LightPosY0,unity_4LightPosZ0,
            unity_LightColor[0].rgb,unity_LightColor[1].rgb,unity_LightColor[2].rgb,unity_LightColor[3].rgb,
            unity_4LightAtten0,i.worldPos,i.normal);
        #endif
    }

    float4 ApplyFog(float4 color,Interpolators i)
    {
        #if FOG_ON
            float viewDistance = length(_WorldSpaceCameraPos - i.worldPos.xyz);
            #if FOG_DEPTH
                viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
            #endif
            UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
            float3 fogColor = 0;
            #if defined(FORWARD_BASE_PASS)
                fogColor = unity_FogColor.rgb;
            #endif
            color.rgb = lerp(fogColor, color.rgb, saturate(unityFogFactor));
        #endif
        return color;
    }
    Interpolators MyVertexProgram(VertexData v)
    {
        Interpolators i;
        // i.localPosition = v.position.xyz;
        i.pos = UnityObjectToClipPos(v.vertex);
        i.worldPos.xyz = mul(unity_ObjectToWorld, v.vertex);
        #if FOG_DEPTH
            i.worldPos.w = i.pos.z;
        #endif
        i.normal = UnityObjectToWorldNormal(v.normal);
        
        #if defined(BINORMAL_PER_FRAGMENT)
            i.tangent = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
        #else
            i.tangent = UnityObjectToWorldDir(v.tangent.xyz);
            i.binormal = CreateBinormal(i.normal, i.tangent, v.tangent.w);
        #endif
        
        i.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
        i.uv.zw = TRANSFORM_TEX(v.uv, _DetailTex);

        #if defined(LIGHTMAP_ON)
            i.lightmapUV =  v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
        #endif
        // #if defined(SHADOWS_SCREEN)
        // // i.shadowCoordinates.xy = (float2(i.position.x, -i.position.y) + i.position.w) * 0.5;
        // // i.shadowCoordinates.zw = i.position.zw;
        // i.shadowCoordinates = ComputeScreenPos(i.position);
        // #endif
        TRANSFER_SHADOW(i);
        
        ComputeVertexLightColor(i);
        // i.normal =mul(transpose((float3x3)unity_WorldToObject),v.normal);
        //
        // i.normal = normalize(i.normal);
        return i;
    }

    UnityLight CreateLight(Interpolators i)
    {
        UnityLight light;
        #if defined(DEFERRED_PASS)
            light.dir = float3(0, 1, 0);
            light.color = 0;
        #else
            #if defined(POINT) || defined(POINT_COOKIE) || defined(SPOT)
                light.dir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos);
            #else
                light.dir = _WorldSpaceLightPos0.xyz;
            #endif
        // float3 lightVec = _WorldSpaceLightPos0.xyz - i.worldPos;
        // float attenuation = 1/(1+dot(lightVec,lightVec));
        // #if defined(SHADOWS_SCREEN)
        // // float attenuation = tex2D(
        // //     _ShadowMapTexture,
        // //     i.shadowCoordinates.xy / i.shadowCoordinates.w
        // // );
        // SHADOW_ATTENUATION(i);
        // #else
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
        // attenuation *= GetOcclusion(i);
        // #endif
            light.color = _LightColor0.rgb * attenuation;
        #endif
        // light.ndotl = DotClamped(i.normal,light.dir);
        return light;
    }

    /**
    * \brief 
    * \param direction 初始的反射方向
    * \param position 采样位置，及i.worldPos
    * \param cubemapPosition cube映射位置
    * \param boxMin 盒子边界
    * \param boxMax 盒子边界
    * \return 
    */
    float3 BoxProjection(float3 direction,float3 position,float4 cubemapPosition,float3 boxMin,float3 boxMax)
    {
        #if UNITY_SPECCUBE_BOX_PROJECTION
            //计算相对位置
            // boxMin -= position;
            // boxMax -= position;

            // float x = (direction.x >0?boxMax.x:boxMin.x)/direction.x;
            // float y = (direction.y >0?boxMax.y:boxMin.y)/direction.y;
            // float z = (direction.z >0?boxMax.z:boxMin.z)/direction.z;
            // float scalar = min(min(x,y),z);
            UNITY_BRANCH
            if (cubemapPosition.w >0)
            {
                float3 factors = ((direction > 0 ? boxMax : boxMin) - position) / direction;
                float scalar = min(min(factors.x, factors.y), factors.z);
                direction = direction * scalar + (position - cubemapPosition);
            }
        #endif
        
        return direction ;
    }

    UnityIndirect CreatIndirectLight(Interpolators i,float3 viewDir)
    {
        UnityIndirect indirectLight;
        indirectLight.diffuse =0;
        indirectLight.specular =0;
        
        #if defined(VERTEXLIGHT_ON)
            indirectLight.diffuse = i.vertexLightColor;
        #endif

        #if defined(FORWARD_BASE_PASS) || defined(DEFERRED_PASS)
            #if defined(LIGHTMAP_ON)
                indirectLight.diffuse =  DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap, i.lightmapUV));
                
                #if defined(DIRLIGHTMAP_COMBINED)
                    float4 lightmapDirection = UNITY_SAMPLE_TEX2D_SAMPLER(unity_LightmapInd, unity_Lightmap, i.lightmapUV);
                    indirectLight.diffuse = DecodeDirectionalLightmap(indirectLight.diffuse, lightmapDirection, i.normal);
                #endif
            #else
                indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
            #endif
            // float3 envSample = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0,i.normal);
            // indirectLight.specular = envSample;
            float3 reflectionDir = reflect(-viewDir,i.normal);
            float roughness = 1-_Smoothness;
            //unity 采用非线性的
            // roughness *=1.7-0.7*roughness;
            // float4 envSample = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0,relectionDir,roughness*UNITY_SPECCUBE_LOD_STEPS);
            // indirectLight.specular = DecodeHDR(envSample,unity_SpecCube0_HDR);
            Unity_GlossyEnvironmentData envData;
            envData.roughness = 1-GetSmoothness(i);
            envData.reflUVW = BoxProjection(
            reflectionDir, i.worldPos,
            unity_SpecCube0_ProbePosition,
            unity_SpecCube0_BoxMin, unity_SpecCube0_BoxMax
            );
            float3 probe0 = Unity_GlossyEnvironment(
            UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
            );
            envData.reflUVW = BoxProjection(
            reflectionDir, i.worldPos,
            unity_SpecCube1_ProbePosition,
            unity_SpecCube1_BoxMin, unity_SpecCube1_BoxMax
            );
            //当目标平台被认为无法处理时，Unity 的着色器也会禁用混合。这是由 UNITY_SPECCUBE_BLENDING 控制的
            #if UNITY_SPECCUBE_BLENDING
                float interpolator = unity_SpecCube0_BoxMin.w;
                UNITY_BRANCH
                if(interpolator <0.9999)
                {
                    float3 probe1 = Unity_GlossyEnvironment(
                    UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0), unity_SpecCube1_HDR, envData
                    );
                    indirectLight.specular = lerp(probe1, probe0, interpolator);
                }
                else
                {
                    indirectLight.specular = probe0;
                }
            #else
                indirectLight.specular = probe0;
            #endif
            float occlusion = GetOcclusion(i);
            indirectLight.diffuse*= occlusion;
            indirectLight.specular*= occlusion;

            
            #if defined(DEFERRED_PASS) && UNITY_ENABLE_REFLECTION_BUFFERS
                indirectLight.specular = 0;
            #endif
        #endif
        return indirectLight;
    }

    void InitializeFragmentNormal(inout Interpolators i)
    {
        // //差分法
        // // float2 delta = float2(_HeightMap_TexelSize.x, 0);
        // // float h1 = tex2D(_HeightMap, i.uv);
        // // float h2 = tex2D(_HeightMap, i.uv + delta);
        //
        // //中心差分法
        // float2 du = float2(_HeightMap_TexelSize.x*0.5, 0);
        // float u1 = tex2D(_HeightMap, i.uv - du);
        // float u2 = tex2D(_HeightMap, i.uv + du);
        // // float3 tu = float3( 1, u2 - u1, 0); //切线
        // // i.normal = float3(u1-u2,1,0);//法线，将x,y调换然后将x的值取反
        //
        // //中心差分法
        // float2 dv = float2(_HeightMap_TexelSize.y*0.5, 0);
        // float v1 = tex2D(_HeightMap, i.uv - dv);
        // float v2 = tex2D(_HeightMap, i.uv + dv);
        // // float3 tv = float3( 0, v2 - v1, 1); //切线
        // // i.normal = float3(0,1,v1-v2);//法线，将x,y调换然后将x的值取反
        //
        // // i.normal = cross(tv,tu); //使用右手定则确定方向，所以使用tv*tu  https://zhuanlan.zhihu.com/p/359975221
        // i.normal = float3(u1-u2,1,v1-v2);

        // //对法线贴图解码 DXT5nm压缩
        // i.normal.xy = tex2D(_NormalMap,i.uv).wy *2 -1;
        // i.normal.xy *= _BumpScale;
        // i.normal.z = sqrt(1- saturate(dot(i.normal.xy,i.normal.xy)));

        // //使用Unity UnpackScaleNormal函数解码法线
        // float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap,i.uv.xy),_BumpScale);
        // float3 detailNormal = UnpackScaleNormal(tex2D(_NormalMap,i.uv.zw),_DetailBumpScale);
        // detailNormal = lerp(float3(0, 0, 1), detailNormal, GetDetailMask(i));
        // // i.normal = float3(mainNormal.xy / mainNormal.z + detailNormal.xy / detailNormal.z, 1);
        // // i.normal = float3(mainNormal.xy  + detailNormal.xy , mainNormal.z*detailNormal.z);
        // float3 tangentSpaceNormal = BlendNormals(mainNormal,detailNormal);
        float3 tangentSpaceNormal = GetTangentSpaceNormal(i);
        // float3 binormal = cross(i.normal,i.tangent.xyz) * i.tangent.w;
        #if defined(BINORMAL_PER_FRAGMENT)
            float3 binormal = CreateBinormal(i.normal, i.tangent.xyz, i.tangent.w);
        #else
            float3 binormal = i.binormal;
        #endif
        //法线从切线空间转换成世界空间。
        i.normal = normalize(
       tangentSpaceNormal.x * i.tangent +
       tangentSpaceNormal.z * i.normal +
       tangentSpaceNormal.y * binormal );
        // i.normal = normalize(i.normal);
    }

    struct FragmentOutput
    {
        #if defined(DEFERRED_PASS)
            float4 gBuffer0:SV_Target0;
            float4 gBuffer1:SV_Target1;
            float4 gBuffer2:SV_Target2;
            float4 gBuffer3:SV_Target3;
        #else
            float4 color:SV_Target;
        #endif
    };

    //PBS 基于物理的着色
    FragmentOutput MyFragmentProgram(Interpolators i)
    {
        float alpha = GetAlpha(i);
        #if defined(_RENDERING_CUTOUT)
            clip(alpha - _Cutoff);
        #endif
        InitializeFragmentNormal(i);
        
        float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
        
        // albedo *=tex2D(_HeightMap,i.uv);
        //albedo *= 1-max(_SpecularTint.r, max(_SpecularTint.g, _SpecularTint.b));

        float3 specularTint;

        float oneMinusReflectivity;
        //EnergyConservationBetweenDiffuseAndSpecular以反射率和高光颜色作为输入，并输出一个调整后的反射率。但它也有第三个输出参数，称为1-减反射率。
        // albedo = EnergyConservationBetweenDiffuseAndSpecular(albedo,_SpecularTint.rgb,oneMinusReflectivity);
        //漫反射
        float3 albedo = DiffuseAndSpecularFromMetallic(GetAlbedo(i), GetMetallic(i), specularTint, oneMinusReflectivity);
        #if defined(_RENDERING_TRANSPARENT)
            albedo *= alpha;
            alpha = 1 - oneMinusReflectivity + alpha * oneMinusReflectivity;
        #endif
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
        UnityLight unity_light = CreateLight(i);
        
        UnityIndirect unity_indirect = CreatIndirectLight(i,viewDir);

        float4 color = UNITY_BRDF_PBS(
        albedo, specularTint,
        oneMinusReflectivity, GetSmoothness(i),
        i.normal, viewDir, unity_light, unity_indirect);

        color.rgb += GetEmission(i);
        #if defined(_RENDERING_FADE) || defined(_RENDERING_TRANSPARENT)
            color.a = alpha;
        #endif

        FragmentOutput output;
        #if defined(DEFERRED_PASS)
            #if !defined(UNITY_HDR_ON)
                color.rgb = exp2(-color.rgb);
            #endif
            output.gBuffer0.rgb = albedo;
            output.gBuffer0.a = GetOcclusion(i);
            output.gBuffer1.rgb = specularTint;
            output.gBuffer1.a = GetSmoothness(i);
            output.gBuffer2 = float4(i.normal * 0.5 + 0.5, 1);
            output.gBuffer3 = color;
        #else
            output.color = ApplyFog(color,i);
        #endif
        return output;
    }
#endif

