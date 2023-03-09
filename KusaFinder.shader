// Japan Street Kusa Finder

Shader "VOIDKoubou/KusaFinder"
{
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
		}

		Cull Off

		GrabPass { "_GrabTexture" }

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
				float2 uv : TEXCOORD0;
				float4 GrabUv : TEXCOORD1;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.GrabUv = UNITY_PROJ_COORD(ComputeGrabScreenPos(o.vertex));
				return o;
			}

			sampler2D _GrabTexture;

			float4 frag (v2f i) : SV_Target
			{
				float2 projUv = i.GrabUv.xy/i.GrabUv.w;

				float4 col = tex2D(_GrabTexture, projUv);

				float2 delta = float2(0.001, 0.001);

				float rrr = 0;

				rrr += tex2D(_GrabTexture, (projUv + float2(-1.0, -1.0) * delta)).r * 1.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 0.0, -1.0) * delta)).r * 1.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 1.0, -1.0) * delta)).r * 1.0;

				rrr += tex2D(_GrabTexture, (projUv + float2(-1.0,  0.0) * delta)).r * 1.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 0.0,  0.0) * delta)).r * 1.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 1.0,  0.0) * delta)).r * 1.0;

				rrr += tex2D(_GrabTexture, (projUv + float2(-1.0,  1.0) * delta)).r * 1.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 0.0,  1.0) * delta)).r * 55.0;
				rrr += tex2D(_GrabTexture, (projUv + float2( 1.0,  1.0) * delta)).r * 1.0;

				col = float4(1-rrr, col.g, col.b, 1);

				return col;
			}
			ENDCG
		}
	}
}
