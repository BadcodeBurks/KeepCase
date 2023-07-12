Shader "Unlit/VertexWindLit"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_NormalMap ("Normal Texture", 2D) = "bump" {}
        _NormalStrength ("Normal Strength", float) = 0.5
        [NoScaleOffset]_RoughnessMap ("Roughness Map", 2D) = "white" {}
        _WindEffectStartHeight ("Wind Effect Height", float) = 0.5
        _WindEffectStrength ("Wind Effect Strength", float) = 0.5
        _AmbientColor ("Ambient Color", Color) = (.5,.8,.8,1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline" = "UniversalPipeline"}
        LOD 100
        cull off

        Pass
        {
            HLSLPROGRAM
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile_instancing

            #pragma vertex vert
            #pragma fragment frag
            // make fog work

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap); SAMPLER(sampler_NormalMap);
            TEXTURE2D(_RoughnessMap); SAMPLER(sampler_RoughnessMap);
            float _WindEffectStartHeight;
            float _WindEffectStrength;
            float4 _AmbientColor;
            float _NormalStrength;

            CBUFFER_START(UnityPerMaterial)

                float4 _MainTex_ST;

            CBUFFER_END
            
            struct appdata
            {
                float4 pos : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 world : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            void InitializeFragNormal(inout v2f i)
            {
                half3 texNormals;
                texNormals.xy = SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.world.xz * _MainTex_ST.xy + _MainTex_ST.zw).wy * 2 - 1;
                texNormals.z = sqrt(1 - saturate(dot(texNormals.xy, texNormals.xy)));
                texNormals = texNormals.xzy;
                i.normal *= 1 + texNormals * _NormalStrength;
                i.normal = normalize(i.normal);
                
            }
            #include "Assets/Shaders/WindProps.hlsl"
            v2f vert (appdata v)
            {
                v2f o;
                o.world = TransformObjectToWorld(v.pos);
                float3 baseWorldPos = unity_ObjectToWorld._m30_m31_m32;
                float3 windOffset = baseWorldPos;
                GetWindFactor(windOffset);
                float windStrength = pow(clamp(o.world.y - _WindEffectStartHeight, 0, 10),2) * _WindEffectStrength;
                windOffset *= windStrength;
                float3 newWorldPos = o.world + windOffset;
                float3 basePosOffset = o.world - baseWorldPos;
                newWorldPos = sqrt(dot(basePosOffset, basePosOffset)) * normalize(newWorldPos - baseWorldPos) + baseWorldPos;
                o.world = newWorldPos;
                o.pos = TransformObjectToHClip(TransformWorldToObject(o.world));
                o.normal = TransformObjectToWorldNormal(v.normal);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                // sample the texture
                half4 albedoColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv * _MainTex_ST.xy + _MainTex_ST.zw);
                clip(albedoColor.a - .5);
                half4 roughness = SAMPLE_TEXTURE2D(_RoughnessMap, sampler_RoughnessMap, i.uv * _MainTex_ST.xy + _MainTex_ST.zw);
                InitializeFragNormal(i);

                InputData inputData = (InputData)0;
                inputData.normalWS = i.normal;
                inputData.positionWS = i.world;
                inputData.positionCS = i.pos;
                inputData.shadowCoord = TransformWorldToShadowCoord(i.world);
                
                SurfaceData surfaceData = (SurfaceData)0;
                surfaceData.albedo = albedoColor.rgb;
                surfaceData.alpha = albedoColor.a;
                surfaceData.smoothness = roughness.r;

                half4 bpShaded = UniversalFragmentBlinnPhong(inputData, surfaceData);
                bpShaded = max(bpShaded, albedoColor * _AmbientColor);
                return bpShaded;
            }
            ENDHLSL
        }
        Pass {
            Name "ShadowCaster"
            Tags{"LightMode" = "ShadowCaster"}
            
            ColorMask 0
            
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct appData {
	            float3 positionOS : POSITION;
	            float3 normalOS : NORMAL;
            };

            struct v2f {
	            float4 positionCS : SV_POSITION;
            };

            float3 _LightDirection;

            float4 GetShadowCasterPositionCS(float3 positionWS, float3 normalWS) {
	            float3 lightDirectionWS = _LightDirection;
	            float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));
            #if UNITY_REVERSED_Z
	            positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #else
	            positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
            #endif
	            return positionCS;
            }

            v2f vert(appData input) {
	            v2f output;

	            VertexPositionInputs posnInputs = GetVertexPositionInputs(input.positionOS);
	            VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS);

	            output.positionCS = GetShadowCasterPositionCS(posnInputs.positionWS, normInputs.normalWS);
	            return output;
            }

            float4 frag(v2f input) : SV_TARGET {
	            return 0;
            }
            ENDHLSL
        }
    }
}
