// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Hidden/SSR"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			#include "UnityDeferredLibrary.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;				
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 rayDirVS : TEXCOORD1;
				float4 vertex : SV_POSITION;
				float2 test : TEXCOORD2;
				float4 test1 : TEXCOORD3;
			};

			#define MAX_TRACE_DIS 50
			#define MAX_IT_COUNT 10
			#define MAX_BS_IT 5			
			uniform float EPSION;
			sampler2D _CameraGBufferTexture0;// Diffuse RGB, Occlusion A
			sampler2D _CameraGBufferTexture1;// Specular RGB, Smoothness A
			sampler2D _CameraGBufferTexture2;// Normal RGB

			float4x4 _NormalMatrix;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				//depth is 1
				o.rayDirVS = mul(unity_CameraInvProjection, float4((float2(v.uv.x, v.uv.y) - 0.5) * 2, 1, 1));
				return o;
			}
			
			sampler2D _MainTex;

			float2 PosToUV(float3 vpos)
			{
				float4 proj_pos = mul(unity_CameraProjection, float4(vpos ,1));
    			float3 screenPos = proj_pos.xyz/proj_pos.w;	
    			return float2(screenPos.x,screenPos.y) * 0.5 + 0.5;
			}

			float compareWithDepth(float3 vpos, out bool isInside)
			{					
				float2 uv = PosToUV(vpos);
    			float depth = tex2D (_CameraDepthTexture, uv);
    			depth = LinearEyeDepth (depth);// * _ProjectionParams.z;   
    			isInside =  uv.x > 0 && uv.x < 1 && uv.y > 0 && uv.y < 1;			
    			return depth + vpos.z;
			}

			bool rayTrace(float3 o, float3 r, float stepSize, out float3 _end, out float _diff)
			{
				float3 start = o;
				float3 end = o;	
				//r = r * sign;			
				for (float i = 1; i <= MAX_IT_COUNT; ++i)
				{
					end = o + r * stepSize * i;
					if(stepSize * i > MAX_TRACE_DIS)
						return false;

					bool isInside = true;
					float diff = compareWithDepth(end, isInside);
					if(!isInside)
						return false;

					_diff = diff;
					_end = end;

					if(_diff < 0)
						return true;
				}
				return false;
			}

			uniform float _StepSize;

			bool BinarySearch(float3 o, float3 r, out float3 hitp, out float debug)
			{
				float3 start = o;
				float3 end = o;
				float sign = 1;
				float stepSize = _StepSize;
				float diff = 0;
				for (int i = 0; i < MAX_BS_IT; ++i)
				{
					if(rayTrace(start, r, stepSize, end, diff))
					{
						if(abs(diff) < EPSION)
						{
							debug = (diff);
							hitp = end;
							return true;
						}

						//sign *= -1;
						start = end - stepSize * r;
						stepSize /= 2;
					}
					else
					{
						return false;
					}
				}
				return false;
			}

			bool rayTrace1(float3 o, float3 r, out float3 hitp, out float debug)
			{
				float3 start = o;
				float3 end = o;
				float stepSize = 0.01;//MAX_TRACE_DIS / MAX_IT_COUNT;
				for (int i = 1; i <= MAX_IT_COUNT; ++i)
				{
					end = o + r * stepSize * i;
					if(length(end - start) > MAX_TRACE_DIS)
						return false;

					bool isInside = true;
					float diff = compareWithDepth(end, isInside);
					if(isInside)
					{
						if(abs(diff) < EPSION)
						{
							debug = diff;
							hitp = end;
							return true;
						}
					}
					else
					{
						return false;
					}
				}
				return false;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col = tex2D(_MainTex, i.uv);
				
				float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
    			depth = Linear01Depth (depth);
    			float3 view_pos = i.rayDirVS.xyz/i.rayDirVS.w * depth;  			   				
    			float3 normal = tex2D (_CameraGBufferTexture2, i.uv).xyz * 2.0 - 1.0;
    			//normal = mul(unity_WorldToObject, float4(normal, 0));
    			normal = mul((float3x3)_NormalMatrix, normal);
    			float3 reflectedRay = reflect(normalize(view_pos), normal);

    			float3 hitp = 0;
    			float debug = 0;
    			if(BinarySearch(view_pos, reflectedRay, hitp, debug))
    			//if(rayTrace1(view_pos, reflectedRay, hitp, debug))
    			{
    				float2 tuv = PosToUV(hitp);	
    				float3 hitCol = tex2D (_CameraGBufferTexture0, tuv);
    				float4 hitSpecA = tex2D (_CameraGBufferTexture1, tuv);
    				float3 _normal = tex2D (_CameraGBufferTexture2, tuv).xyz * 2.0 - 1.0;
    				//col = abs(debug) * 50;
    				//col = fixed4(_normal,1);
    				col += fixed4(hitCol, 1);
    				//col += fixed4((hitCol + hitSpecA.rgb), 1);
    			}
    			return col;
    			//return tex2D(_MainTex, float2(screenPos.x,screenPos.y) * 0.5 + 0.5);

    			//float3 wpos = mul(_CamToWorld, view_pos);


			}
			ENDCG
		}
	}
}
