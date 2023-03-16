// Upgrade NOTE: upgraded instancing buffer 'InstanceProperties' to new syntax.

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

// Upgrade NOTE: replaced 'UNITY_PASS_TEXCUBE(unity_SpecCube1)' with 'UNITY_PASS_TEXCUBE_SAMPLER(unity_SpecCube1,unity_SpecCube0)'

#if !defined(MY_LIGHTING21_INCLUDED)
    #define MY_LIGHTING21_INCLUDED

    #include "My Lighting Input21.cginc"

    #if !defined(ALBEDO_FUNCTION)
        #define ALBEDO_FUNCTION GetAlbedo
    #endif

    void ComputeVertexLightColor(inout InterpolatorsVertex i)
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
    InterpolatorsVertex  MyVertexProgram(VertexData v)
    {
        InterpolatorsVertex  i;
        UNITY_INITIALIZE_OUTPUT(InterpolatorsVertex, i);
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, i);
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

        #if defined(LIGHTMAP_ON) || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
            i.lightmapUV =  v.uv1 * unity_LightmapST.xy + unity_LightmapST.zw;
        #endif

        #if defined(DYNAMICLIGHTMAP_ON)
            i.dynamicLightmapUV = v.uv2 * unity_DynamicLightmapST.xy + unity_DynamicLightmapST.zw;
        #endif
        // #if defined(SHADOWS_SCREEN)
        // // i.shadowCoordinates.xy = (float2(i.position.x, -i.position.y) + i.position.w) * 0.5;
        // // i.shadowCoordinates.zw = i.position.zw;
        // i.shadowCoordinates = ComputeScreenPos(i.position);
        // #endif
         // TRANSFER_SHADOW(i);

        UNITY_TRANSFER_SHADOW(i,v.uv1);//自从 Unity 5.6以来，只有方向阴影的屏幕空间坐标被放在一个插值器中。点光源和聚光灯的阴影坐标现在在片段程序中计算。
        ComputeVertexLightColor(i);
        // i.normal =mul(transpose((float3x3)unity_WorldToObject),v.normal);
        //
        // i.normal = normalize(i.normal);

        #if defined(_PARALLAX_MAP)
            #if defined(PARALLAX_SUPPORT_SCALED_DYNAMIC_BATCHING)
                v.tangent.xyz = normalize(v.tangent.xyz);
                v.normal = normalize(v.normal);
            #endif
            float3x3 objectToTangent = float3x3(
                v.tangent.xyz,
                cross(v.normal,v.tangent.xyz) *v.tangent.w,
                v.normal
            );
            i.tangentViewDir = mul(objectToTangent,ObjSpaceViewDir(v.vertex)); //ObjSpaceViewDir  对象空间中顶点位置的视图方向
        #endif
        return i;
    }

    float FadeShadows(Interpolators i,float attenuation)
    {
        #if HANDLE_SHADOWS_BLENDING_IN_GI || ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
            #if ADDITIONAL_MASKED_DIRECTIONAL_SHADOWS
                attenuation = SHADOW_ATTENUATION(i);
            #endif
            float viewZ= dot(_WorldSpaceCameraPos - i.worldPos,UNITY_MATRIX_V[2].xyz);
            float shadowFadeDistance = UnityComputeShadowFadeDistance(i.worldPos,viewZ);
            float shadowFade = UnityComputeShadowFade(shadowFadeDistance);
            float bakedAttenuation = UnitySampleBakedOcclusion(i.lightmapUV, i.worldPos);
            attenuation = UnityMixRealtimeAndBakedShadows(attenuation, bakedAttenuation, shadowFade);
        #endif
        return attenuation;
    }

    void ApplySubtractiveLighting(Interpolators i, inout UnityIndirect indirectLight)
    {
        #if SUBTRACTIVE_LIGHTING
            UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos.xyz);
            attenuation = FadeShadows(i, attenuation);

            float ndotl = saturate(dot(i.normal, _WorldSpaceLightPos0.xyz));
            float3 shadowedLightEstimate = ndotl * (1 - attenuation) * _LightColor0.rgb;
            float3 subtractedLight = indirectLight.diffuse - shadowedLightEstimate;
            subtractedLight = max(subtractedLight, unity_ShadowColor.rgb);
            subtractedLight = lerp(subtractedLight, indirectLight.diffuse, _LightShadowData.x);
            indirectLight.diffuse = min(subtractedLight, indirectLight.diffuse);
        #endif
    }
    UnityLight CreateLight(Interpolators i)
    {
        UnityLight light;
        #if defined(DEFERRED_PASS) || SUBTRACTIVE_LIGHTING
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
            attenuation = FadeShadows(i,attenuation);
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

                ApplySubtractiveLighting(i, indirectLight);
            // #else
            //     indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
            #endif

            #if defined(DYNAMICLIGHTMAP_ON)
                float3 dynamicLightDiffuse = DecodeRealtimeLightmap(UNITY_SAMPLE_TEX2D(unity_DynamicLightmap, i.dynamicLightmapUV) );

                #if defined(DIRLIGHTMAP_COMBINED)
                    float4 dynamicLightmapDirection  = UNITY_SAMPLE_TEX2D_SAMPLER(unity_DynamicDirectionality, unity_DynamicLightmap, i.dynamicLightmapUV);
                    indirectLight.diffuse += DecodeDirectionalLightmap(dynamicLightDiffuse, dynamicLightmapDirection, i.normal);
                #else
                    indirectLight.diffuse += dynamicLightDiffuse;
                #endif
            #endif

            #if !defined(LIGHTMAP_ON) && !defined(DYNAMICLIGHTMAP_ON)
                #if UNITY_LIGHT_PROBE_PROXY_VOLUME
                    if (unity_ProbeVolumeParams.x == 1)
                    {
                        indirectLight.diffuse = SHEvalLinearL0L1_SampleProbeVolume(float4(i.normal, 1), i.worldPos);
                        indirectLight.diffuse = max(0, indirectLight.diffuse);
                        #if defined(UNITY_COLORSPACE_GAMMA)
                            indirectLight.diffuse =LinearToGammaSpace(indirectLight.diffuse);
                        #endif
                    }
                    else
                    {
                        indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
                    }
                #else
                    indirectLight.diffuse += max(0, ShadeSH9(float4(i.normal, 1)));
                #endif
            #endif

                ApplySubtractiveLighting(i, indirectLight);
        
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

    float GetParallaxHeight(float2 uv)
    {
        return tex2D(_ParallaxMap,uv).g;
    }

/**
 * \brief 简单的偏移视差贴图
 * \param uv 
 * \param viewDir 
 * \return 
 */
    float2 ParallaxOffset(float2 uv,float2 viewDir)
    {
        float height = GetParallaxHeight(uv);
        height -=0.5;
        height *= _ParallaxStrength;
        return viewDir * height;
    }

/**
 * \brief 基于光线追踪的视差图
 * \param uv 
 * \param viewDir 
 * \return 
 */
    float2 ParallaxRaymarching(float2 uv,float2 viewDir)
    {
        #if !defined(PARALLAX_RAYMARCHING_STEPS)
            #define PARALLAX_RAYMARCHING_STEPS 10
        #endif
        float2 uvOffset =0;
        float stepSize = 1.0/PARALLAX_RAYMARCHING_STEPS;
        float2 uvDelta = viewDir * (stepSize * _ParallaxStrength);

        float stepHeight =1;
        float surfaceHeight = GetParallaxHeight(uv);

        float2 prevUVOffset = uvOffset;
        float prevStepHeight = stepHeight;
        float prevSurfaceHeight = surfaceHeight;
        for (int i = 1; i < PARALLAX_RAYMARCHING_STEPS && stepHeight > surfaceHeight; i++)
        {
            prevUVOffset = uvOffset;
            prevStepHeight = stepHeight;
            prevSurfaceHeight = surfaceHeight;
            uvOffset -= uvDelta;
            stepHeight -= stepSize;
            surfaceHeight = GetParallaxHeight(uv + uvOffset);            
        }
        
        #if !defined(PARALLAX_RAYMARCHING_SEARCH_STEPS)
            #define PARALLAX_RAYMARCHING_SEARCH_STEPS 0
        #endif
        #if PARALLAX_RAYMARCHING_SEARCH_STEPS > 0
            for (int i = 0; i < PARALLAX_RAYMARCHING_SEARCH_STEPS; i++)
            {
                uvDelta *= 0.5;
                stepSize *= 0.5;

                if (stepHeight < surfaceHeight)
                {
                    uvOffset += uvDelta;
                    stepHeight += stepSize;
                }
                else
                {
                    uvOffset -= uvDelta;
                    stepHeight -= stepSize;
                }
                surfaceHeight = GetParallaxHeight(uv + uvOffset);    
            }
        #elif defined(PARALLAX_RAYMARCHING_INTERPOLATE)
            float prevDifference = prevStepHeight - prevSurfaceHeight;
            float difference = surfaceHeight - stepHeight;
            float t = prevDifference / (prevDifference + difference);
            uvOffset = prevUVOffset - uvDelta * t;
        #endif
        return uvOffset;
    }
    void ApplyParallax(inout Interpolators i)
    {
        #if defined(_PARALLAX_MAP)
            i.tangentViewDir = normalize(i.tangentViewDir);
            #if !defined(PARALLAX_OFFSET_LIMITING)
                #if !defined(PARALLAX_BIAS)
                    #define PARALLAX_BIAS 0.42
                #endif
                i.tangentViewDir.xy /= (i.tangentViewDir.z + PARALLAX_BIAS);
            #endif

            #if !defined(PARALLAX_FUNCTION)
                #define PARALLAX_FUNCTION ParallaxOffset
            #endif
            float2 uvOffset = PARALLAX_FUNCTION(i.uv.xy,i.tangentViewDir.xy);
            i.uv.xy += uvOffset;
            i.uv.zw += uvOffset  * (_DetailTex_ST.xy / _MainTex_ST.xy);
       
        #endif
    }
    struct FragmentOutput
    {
        #if defined(DEFERRED_PASS)
            float4 gBuffer0:SV_Target0;
            float4 gBuffer1:SV_Target1;
            float4 gBuffer2:SV_Target2;
            float4 gBuffer3:SV_Target3;
            
            #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                float4 gBuffer4 : SV_Target4;
            #endif
        #else
            float4 color:SV_Target;
        #endif
    };

    //PBS 基于物理的着色
    FragmentOutput MyFragmentProgram(Interpolators i)
    {
        UNITY_SETUP_INSTANCE_ID(i);
        #if defined(LOD_FADE_CROSSFADE)
            UnityApplyDitherCrossFade(i.vpos);
        #endif

        ApplyParallax(i);
        
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
        float3 albedo = DiffuseAndSpecularFromMetallic(ALBEDO_FUNCTION(i), GetMetallic(i), specularTint, oneMinusReflectivity);
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
        
            #if defined(SHADOWS_SHADOWMASK) && (UNITY_ALLOWED_MRT_COUNT > 4)
                float2 shadowUV = 0;
                #if defined(LIGHTMAP_ON)
                    shadowUV = i.lightmapUV;
                #endif
                output.gBuffer4 = UnityGetRawBakedOcclusions(shadowUV, i.worldPos.xyz);
            #endif
        #else
            output.color = ApplyFog(color,i);
        #endif
        return output;
    }
#endif

