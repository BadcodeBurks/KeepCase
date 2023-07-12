//Commented sections are for tessellation, which is not currently working

Shader "Burk/IslandShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        [NoScaleOffset]_MainTexNormal ("Normal Texture", 2D) = "white" {}
        _NormalStrength ("Normal Strength", Range(0, 10)) = 0.1
        [NoScaleOffset]_MainTexRoughness ("Roughness Texture", 2D) = "white" {}
        _LowHeightColor ("Low Height Color", Color) = (1,1,1,1)
        _RTBlendColor (" Render Texture Blend Color", Color) = (1,1,1,1)
        _RT (" Render Texture", 2D) = "white" {}
        _RtNormalDist (" Render Texture Normal Distance", Range(0, 1)) = 0.3
        _RTNormalStrength (" Render Texture Normal Strength", Range(0, 10)) = 4
//        _TesselationFactor ("Tesselation Factor", Range(1, 4)) = 3,
        
        _BlendHeight ("Blend Height", float) = 0
        _BlendHeightRange ("Blend Height Range", Range(0, 1)) = 0.1
        
        _AmbienceColor ("Ambience Color", Color) = (1,1,1,1)
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "RenderPipeline" = "UniversalPipeline" }

        Pass
        {

            HLSLPROGRAM

            //#pragma target 5.0 
            
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            //#pragma multi_compile_instancing

            //#pragma shader_feature_local _PARTITIONING_INTEGER _PARTITIONING_FRAC_EVEN _PARTITIONING_FRAC_ODD _PARTITIONING_POW2
            
            #pragma vertex vert
            // #pragma hull Hull
            // #pragma domain Domain
            #pragma fragment frag
            
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            struct appData
            {
                float4 pos   : POSITION;
                half3 normal : NORMAL;
                //UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            
            // struct tcp {
            //     float3 positionWS : INTERNALTESSPOS;
            //     float3 normalWS : NORMAL;
            //     //UNITY_VERTEX_INPUT_INSTANCE_ID
            // };
            //
            //
            // struct TessellationFactors {
            //     float edge[3] : SV_TessFactor;
            //     float inside : SV_InsideTessFactor;
            //     //TODO: Bezier control points
            // };

            
            // struct Interpolators {
            //     float3 normalWS                 : TEXCOORD0;
            //     float3 positionWS               : TEXCOORD1;
            //     float4 positionCS               : SV_POSITION;
            //     UNITY_VERTEX_INPUT_INSTANCE_ID
            //     UNITY_VERTEX_OUTPUT_STEREO
            // };

          //   #define BARYCENTRIC_INTERPOLATE(fieldName) \
		        // patch[0].fieldName * barycentricCoordinates.x + \
		        // patch[1].fieldName * barycentricCoordinates.y + \
		        // patch[2].fieldName * barycentricCoordinates.z
          //   
            struct v2f
            {
                float4 pos  : SV_POSITION;
                half3 normal: TEXCOORD0;
                half3 world : TEXCOORD1;
                // UNITY_VERTEX_INPUT_INSTANCE_ID
                // UNITY_VERTEX_OUTPUT_STEREO
            };

            TEXTURE2D(_MainTex); SAMPLER(sampler_MainTex);
            TEXTURE2D(_MainTexNormal); SAMPLER(sampler_MainTexNormal);
            TEXTURE2D(_MainTexRoughness); SAMPLER(sampler_MainTexRoughness);
            TEXTURE2D(_RT); SAMPLER(sampler_RT);
            float4 _RTBlendColor;
            // float _TesselationFactor;
            float _NormalStrength;
            float4 _LowHeightColor;
            float _BlendHeight;
            float _BlendHeightRange;
            float4 _AmbienceColor;
            float _RtNormalDist;
            float _RTNormalStrength;

            CBUFFER_START(UnityPerMaterial)

                float4 _MainTex_ST;
                float4 _RT_ST;

            CBUFFER_END

            void InitializeFragNormal(inout v2f i)
            {
                half3 texNormals;
                texNormals.xy = SAMPLE_TEXTURE2D(_MainTexNormal, sampler_MainTexNormal, i.world.xz * _MainTex_ST.xy + _MainTex_ST.zw).wy * 2 - 1;
                texNormals.z = sqrt(1 - saturate(dot(texNormals.xy, texNormals.xy)));
                texNormals = texNormals.xzy;
                i.normal *= 1 + texNormals * _NormalStrength;
                i.normal = normalize(i.normal);
                
            }

            void SampleRT(float2 uv, inout half3 normal)
            {
                //5 point sample
                float2 northOffset = float2(0, 1) * _RT_ST.xy * _RtNormalDist;
                float2 southOffset = float2(0, -1) * _RT_ST.xy * _RtNormalDist;
                float2 eastOffset = float2(1, 0) * _RT_ST.xy * _RtNormalDist;
                float2 westOffset = float2(-1, 0) * _RT_ST.xy * _RtNormalDist;
                half north = SAMPLE_TEXTURE2D(_RT, sampler_RT, uv * _RT_ST.xy + _RT_ST.zw + northOffset).r;
                half south = SAMPLE_TEXTURE2D(_RT, sampler_RT, uv * _RT_ST.xy + _RT_ST.zw + southOffset).r;
                half east = SAMPLE_TEXTURE2D(_RT, sampler_RT, uv * _RT_ST.xy + _RT_ST.zw + eastOffset).r;
                half west = SAMPLE_TEXTURE2D(_RT, sampler_RT, uv * _RT_ST.xy + _RT_ST.zw + westOffset).r;
                normal = normalize(normal + half3(east - west, 0, north - south) * _RTNormalStrength);
            }

            // tcp vert(appData IN)
            // {
            //     tcp OUT;
            //     UNITY_SETUP_INSTANCE_ID(IN);
            //     UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
            //     VertexPositionInputs posIn = GetVertexPositionInputs(IN.pos);
            //     VertexNormalInputs normalIn = GetVertexNormalInputs(IN.normal);
            //
            //     OUT.positionWS = posIn.positionWS;
            //     OUT.normalWS = normalIn.normalWS;
            //     return OUT;
            // }

            // [domain("tri")]
            // [outputcontrolpoints(3)]
            // [outputtopology("triangle_cw")]
            // [patchconstantfunc("PatchConstantFunction")]
            // [partitioning("integer")]
            // tcp Hull(InputPatch<tcp, 3> patch, uint id : SV_OutputControlPointID)
            // {
            //
            //     return patch[id];
            // }

            // TessellationFactors PatchConstantFunction(InputPatch<tcp, 3> patch) {
            //     UNITY_SETUP_INSTANCE_ID(patch[0]); // Set up instancing
            //     // Calculate tessellation factors
            //     TessellationFactors f;
            //     
            //     f.edge[0] = _TesselationFactor;
            //     f.edge[1] = _TesselationFactor;
            //     f.edge[2] = _TesselationFactor;
            //     f.inside = _TesselationFactor;
            //     return f;
            // }

            // [domain("tri")]
            // v2f Domain(
            //     TessellationFactors factors,
            //     OutputPatch<tcp, 3> patch,
            //     float3 barycentricCoordinates : SV_DomainLocation) {
            //
            //     v2f output;
            //
            //     // Setup instancing and stereo support (for VR)
            //     UNITY_SETUP_INSTANCE_ID(patch[0]);
            //     UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
            //     UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            //
            //     float3 positionWS = BARYCENTRIC_INTERPOLATE(positionWS);
            //     float3 normalWS = BARYCENTRIC_INTERPOLATE(normalWS);
            //
            //     
            //     
            //     output.pos = TransformWorldToHClip(positionWS);
            //     output.normal = normalWS;
            //     output.world = positionWS;
            //
            //     return output;
            // }
            
            v2f vert(appData IN)
            {
                v2f OUT;
                // UNITY_SETUP_INSTANCE_ID(IN);
                // UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                OUT.pos = TransformObjectToHClip(IN.pos.xyz);
                OUT.normal = TransformObjectToWorldNormal(IN.normal);
                OUT.world = TransformObjectToWorld(IN.pos);

                
                return OUT;
            }
        
            
            half4 frag(v2f i) : SV_Target
            {
                float2 uv = i.world.xz;
                half4 mainTexColor = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv * _MainTex_ST.xy + _MainTex_ST.zw);
                half3 roughness = SAMPLE_TEXTURE2D(_MainTexRoughness, sampler_MainTexRoughness, uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
                // half3 normal = SAMPLE_TEXTURE2D(_MainTexNormal, sampler_MainTexNormal, uv * _MainTex_ST.xy + _MainTex_ST.zw).rgb;
                InitializeFragNormal(i);
                float heightBlend = clamp((i.world.y - _BlendHeight)/_BlendHeightRange, 0.0, 1.0);
                float rtVal = SAMPLE_TEXTURE2D(_RT, sampler_RT, uv * _RT_ST.xy + _RT_ST.zw).r;
                if(rtVal > 0.2)
                {
                    SampleRT(uv, i.normal);
                }
                half4 albedoColor = lerp(mainTexColor, _RTBlendColor, rtVal);
                albedoColor = albedoColor * lerp(half4(1,1,1,1), _LowHeightColor, 1-heightBlend);
                
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
                half4 finalColor = max(bpShaded, albedoColor * _AmbienceColor);
                return finalColor;
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