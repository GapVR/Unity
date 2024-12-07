// ScreenToPixel (pixelBlock)
// v0.1 241124 https://github.com/GapVR

Shader "VOIDKoubou/ScreenToPixel"
{
	Properties
	{
		_FadeMin ("Fade Min", Float) = 0.06
		_FadeLength ("Fade Length", Float) = 0.1
		_DisplayAngle ("Display Angle", Range( 0, 1)) = 0.7

		_Res("Resolution", Int) = 48
		_StepSize("Step Size", Range( -1, 1)) = 1

		_MainTex ("Texture", 2D) = "white" {}
		_MaskTex ("Mask", 2D) = "white" {}

		[Header(Rendering)]

		[Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back

		GrabPass { "_GrabTexture" }

		ZWrite [_ZWrite]

		Pass
		{
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 uv : TEXCOORD0;
				float2 uv2 : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				float dotproduct : TEXCOORD3;
			};

			sampler2D _GrabTexture;
			sampler2D _MainTex;
			sampler2D _MaskTex;
			int _Res;
			float _StepSize;
			float _FadeMin;
			float _FadeLength;
			float _DisplayAngle;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.uv2 = v.uv2;
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				o.dotproduct = dot(normalize(v.normal), normalize(ObjSpaceViewDir(v.vertex)));
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				fixed4 mainCol = tex2D(_MainTex, i.uv.xy);

				float distanceFromCamera = length(_WorldSpaceCameraPos - i.worldPos);
				if (distanceFromCamera <= (_FadeMin + _FadeLength))
				{
					if ((length(tex2D(_MaskTex, i.uv.xy).rgb - fixed3(0,0,0).rgb) < 0.01) && (i.dotproduct > _DisplayAngle))
					{
						fixed4 c;
						float2 uv2 = i.uv2;

						#ifdef USING_STEREO_MATRICES
							uv2.x *= 0.5;
						#endif

						c = tex2D(_GrabTexture, floor(uv2.xy * _Res)/_Res);
						c *= step(cos((uv2.x * _Res * 2) * UNITY_PI), _StepSize);
						c *= step(cos((uv2.y * _Res * 2) * UNITY_PI), _StepSize);
						c = lerp(mainCol, c, saturate(c.a));

						float fadeFactor = saturate((distanceFromCamera - _FadeMin)/_FadeLength);
						return lerp(c, mainCol, fadeFactor);
					}
				}

				return mainCol;
			}
			ENDCG
		}
	}
}