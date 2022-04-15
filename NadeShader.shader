Shader "VOIDKoubou/NadeShader"
{
	Properties
	{
		// Near Overlay (From Vertex)
		_NearColor ("Near Color", Color) = (0.0,0.0,0.0,1.0)
		_NearMinFalloff ("Near Min Falloff", Float) = 0.015
		_NearMaxFalloff ("Near Max Falloff", Float) = 0.2
		[Toggle] _NearOnly ("Near Only", Int) = 0

		// Far Overlay (From Object Centre)
		_FarColor ("Far Color", Color) = (0.0,0.0,0.0,1.0)
		_FarMinFalloff ("Far Min Falloff", Float) = 0.00
		_FarMaxFalloff ("Far Max Falloff", Float) = 0.2

		// Misc
		_Opacity ("Opacity", Float) = 1.0
		_Range ("Max Range", Float) = 0.2
		_Overlap ("Overlap", Float) = 0.1

		// Rendering
		[Enum(UnityEngine.Rendering.CullMode)] _CullMode ("Cull Mode", Float) = 1.0
		[Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 0
		[Enum(UnityEngine.Rendering.CompareFunction)] _ZTest ("ZTest", Int) = 0
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendSource ("Blend Source", Int) = 2
		[Enum(UnityEngine.Rendering.BlendMode)] _BlendDestination ("Blend Destination", Int) = 10
		[Enum(UnityEngine.Rendering.BlendOp)] _BlendOp ("Blend Mode", Int) = 0

		//// Stencil
		// _StencilRef ("Ref", Int) = 0
		// _StencilReadMask ("Read Mask", Int) = 255
		// _StencilWriteMask ("Write Mask", Int) = 255
		// [Enum(UnityEngine.Rendering.CompareFunction)] _StencilComp ("Compare Function", Int) = 0
		// [Enum(UnityEngine.Rendering.StencilOp)] _StencilPassOp ("Pass Operation", Int) = 0
		// [Enum(UnityEngine.Rendering.StencilOp)] _StencilFailOp ("Fail Operation", Int) = 0
		// [Enum(UnityEngine.Rendering.StencilOp)] _StencilZFailOp ("ZFail Operation", Int) = 0
	}
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent+1000"
			"VRCFallback"="Hidden"
		}
		
		// Stencil
		// {
			// Ref [_StencilRef]
			// ReadMask [_StencilReadMask]
			// WriteMask [_StencilWriteMask]
			// Comp [_StencilComp]
			// Pass [_StencilPassOp]
			// Fail [_StencilFailOp]
			// ZFail [_StencilZFailOp]
		// }
		
		ZTest [_ZTest]
		Cull [_CullMode]
		ZWrite [_ZWrite]
		ColorMask RGBA
		
		BlendOp [_BlendOp]
		Blend [_BlendSource] [_BlendDestination]

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
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				float distFromPoint : TEXCOORD0;
				float4 projPos : TEXCOORD1;
				float4 rayFromCamera : TEXCOORD2;
			};

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			float4 _NearColor;
			float4 _FarColor;
			float _Opacity;

			int _NearOnly;

			float _NearMinFalloff;
			float _NearMaxFalloff;
			float _FarMinFalloff;
			float _FarMaxFalloff;

			float _Range;
			float _Overlap;

			#define NaN asfloat(0x7FC00000)

			float calculateCameraDepth(float2 screenPos, float4 rayFromCamera, float perspectiveDivide)
			{
				float z = tex2Dlod(_CameraDepthTexture, float4(screenPos * perspectiveDivide, 0, 0)).r;
				return rcp(z/UNITY_MATRIX_P._34 + rayFromCamera.w);
			}

			// Dj Lukis.LT's oblique view frustum correction (VRChat mirrors use such view frustum)
			// https://github.com/lukis101/VRCUnityStuffs/blob/master/Shaders/DJL/Overlays/WorldPosOblique.shader
			#define UMP UNITY_MATRIX_P
			inline float4 CalculateObliqueFrustumCorrection()
			{
				float x1 = -UMP._31 / (UMP._11 * UMP._34);
				float x2 = -UMP._32 / (UMP._22 * UMP._34);
				return float4(x1, x2, 0, UMP._33 / UMP._34 + x1 * UMP._13 + x2 * UMP._23);
			}
			static float4 ObliqueFrustumCorrection = CalculateObliqueFrustumCorrection();
			inline float CorrectedLinearEyeDepth(float z, float correctionFactor)
			{
				return 1.f / (z / UMP._34 + correctionFactor);
			}
			#undef UMP

			v2f vert (appdata v)
			{
				v2f o;
				o = (v2f) 0;	// or get intialise error

				// from object center
				o.distFromPoint = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz);
				// discard if out of range
				if (o.distFromPoint > _Range)
				{
					o.vertex.w = NaN;
					return o;
				}

				v.vertex.xyz += _Overlap * v.normal;

				o.vertex = UnityObjectToClipPos(v.vertex);
				o.projPos = ComputeScreenPos(o.vertex);
				o.rayFromCamera.xyz = mul(unity_ObjectToWorld, v.vertex).xyz - _WorldSpaceCameraPos;	// _WorldSpaceCameraPos : unity built-in
				o.rayFromCamera.w = dot(o.vertex, ObliqueFrustumCorrection);	// mirror correction

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float depth = calculateCameraDepth(i.projPos.xy, i.rayFromCamera, rcp(i.vertex.w));	// from surfaces

				float nearfalloff = 1 - smoothstep(_NearMinFalloff, _NearMaxFalloff, depth);
				float4 nearcolor = _NearColor * nearfalloff * _Opacity;

				if (_NearOnly)
				{
					return nearcolor;
				}
				else
				{
					float4 farcolor = _FarColor * (1 - smoothstep(_FarMinFalloff, _FarMaxFalloff, i.distFromPoint)) * _Opacity;
					return lerp(nearcolor,farcolor,1 - nearfalloff);
				}
			}
			ENDCG
		}
	}
}
