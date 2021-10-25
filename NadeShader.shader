Shader "VOIDKoubou/NadeShader"
{
	Properties
	{
		_Range ("Range", Float) = 0.15
	}
	SubShader
	{
		Tags
		{
			"IgnoreProjector"="True"
			"Queue"="Transparent"
			"RenderType"="Transparent"
		}

		Cull Front
		ZTest Greater
		ZWrite Off
		Blend DstColor Zero

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float _Range;

			uniform sampler2D _CameraDepthTexture;

			struct appdata
			{
				float4 vertex : POSITION;
			};

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 projPos : TEXCOORD0;
			};

			v2f vert (appdata v)
			{
				v2f o;
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				o.pos = UnityObjectToClipPos(v.vertex);
				o.projPos = ComputeScreenPos(o.pos);
				COMPUTE_EYEDEPTH(o.projPos.z);
				return o;
			}

			float4 frag(v2f i) : SV_Target
			{
				float4 objPos = mul(unity_ObjectToWorld, float4(0,0,0,1));
				float2 sceneUVs = (i.projPos.xy / i.projPos.w);
				float lerpA = step(distance(_WorldSpaceCameraPos, objPos.rgb), _Range);
				float lerpB = step(_Range, distance(_WorldSpaceCameraPos, objPos.rgb));
				float lerpC = saturate(max(0, LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sceneUVs)) - _ProjectionParams.g)) * (1.0/_Range);
				float banana = lerp((lerpA*lerpC) + (lerpB*1.0), lerpC, lerpA*lerpB);
				return fixed4(banana, banana, banana, 1);
			}
		ENDCG
		}
	}
}
