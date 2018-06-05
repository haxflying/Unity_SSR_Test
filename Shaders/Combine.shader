Shader "Hidden/Combine"
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

			sampler2D _b4Blur;
			sampler2D _gbuffer3;
			sampler2D _CameraGBufferTexture3;

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col_after = tex2D(_MainTex, i.uv);//blured reflect
				fixed4 col_b4 = tex2D(_b4Blur, i.uv);//unblured reflect
				fixed4 ref = tex2D(_gbuffer3, i.uv);//original scene
				return fixed4(ref.rgb + lerp(col_b4.rgb, col_after.rgb, clamp(0,1, col_after.a * 2)), 1);
			}
			ENDCG
		}
	}
}
