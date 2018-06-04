Shader "Hidden/Blur"
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

			sampler2D _CameraGBufferTexture0;// Diffuse RGB, Occlusion A
			sampler2D _CameraGBufferTexture1;// Specular RGB, Smoothness A
			sampler2D _CameraGBufferTexture2;// Normal RGB
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
				fixed4 col = tex2Dlod(_CameraGBufferTexture3, half4(i.uv,0,5));
				float4 x = ddx(col);
				float4 y = ddy(col);
				col += (x + y) * 5;
				return col;
			}
			ENDCG
		}
	}
}
