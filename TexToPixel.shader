Shader "VOIDKoubou/TexToPixel"
{
	Properties
	{
		_MainTex("_MainTex", 2D) = "white" {}
		_Res("Resolution", Int) = 32
		_StepSize("Step Size", Range( -1 , 1)) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Off

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;
			int _Res;
			float _StepSize;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				float2 uv_MainTex = i.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				float4 c;
				c = tex2D(_MainTex, floor(uv_MainTex * _Res)/_Res);
				c *= step(cos((uv_MainTex.x * _Res * 2) * UNITY_PI), _StepSize);
				c *= step(cos((uv_MainTex.y * _Res * 2) * UNITY_PI), _StepSize);
				return c;
			}
			ENDCG
		}
	}
}