// NadeShader - Depth-based screen colourization shader
// Copyright (c) 2021-2025 ぎん（Gin）
// 20250909 v2.1 - range as % of object size. smoothed range falloffs. changed final blend. update copyright attribution.
// 20220417 v2.0 - code refactor. added near-only/far-only/both modes.
// 20211014 v1.0 - initial release (under attribution to "Ginnungagap")

Shader "VOIDKoubou/NadeShader"
{
	Properties
	{
		[Enum(Both, 0, Near Only, 1, Far Only, 2)] _OverlayType ("Overlay Type", Int) = 0

		// Near Overlay (From Vertex)
		_NearColor ("Near Color", Color) = (0.0,0.0,0.0,1.0)
		_NearMinFalloff ("Near Min Falloff", Float) = 0.01
		_NearMaxFalloff ("Near Max Falloff", Float) = 0.2
		_NearOpacity ("Near Opacity", Float) = 1.0
		_NearHueShift ("Near Hue Shift", Range(0, 1)) = 0

		// Far Overlay (From Object Centre)
		_FarColor ("Far Color", Color) = (0.0,0.0,0.0,1.0)
		_FarMinFalloff ("Far Min Falloff", Float) = 0.0
		_FarMaxFalloff ("Far Max Falloff", Float) = 0.2
		_FarOpacity ("Far Opacity", Float) = 1.0
		_FarHueShift ("Far Hue Shift", Range(0, 1)) = 0

		// Misc
		_Range ("Max Range [0: unlimited]", Float) = 0.2
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
				float objectSize : TEXCOORD3;
			};

			UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);

			float4 _NearColor;
			float4 _FarColor;
			float _NearOpacity;
			float _FarOpacity;
			float _NearHueShift;
			float _FarHueShift;

			int _OverlayType;

			float _NearMinFalloff;
			float _NearMaxFalloff;
			float _FarMinFalloff;
			float _FarMaxFalloff;

			float _Range;
			float _Overlap;

			#define NaN asfloat(0x7FC00000)

			float calculateCameraDepth(float2 screenPos, float4 rayFromCamera, float perspectiveDivide)
			{
				float z = tex2D(_CameraDepthTexture, saturate(screenPos * perspectiveDivide)).r;
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

			// Fast branchless RGB to HSV conversion in GLSL by sam
			// https://web.archive.org/web/20200207113336/http://lolengine.net/blog/2013/07/27/rgb-to-hsv-in-glsl
			float3 rgb2hsv(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
				float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

				float d = q.x - min(q.w, q.y);
				float e = 1.0e-10;
				return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float3 hsv2rgb(float3 c)
			{
				float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
				float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
				return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
			}

			float4 hueshift(float4 c, float shift)
			{
				if (shift > 0.001)
				{
					float3 hsv = rgb2hsv(c.rgb);
					hsv.x = frac(hsv.x + shift + 1.0);
					return float4(hsv2rgb(hsv),c.a);
				}
				else
					return c;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o = (v2f) 0;	// or get intialise error

				// from object center
				o.distFromPoint = distance(_WorldSpaceCameraPos, mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz);
				// discard if out of range
				if (_Range > 0)
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

				float3 objectMin = mul(unity_ObjectToWorld, float4(-0.5, -0.5, -0.5, 1.0)).xyz;
				float3 objectMax = mul(unity_ObjectToWorld, float4(0.5, 0.5, 0.5, 1.0)).xyz;
				o.objectSize = length(objectMax - objectMin);

				return o;
			}

			fixed4 frag (v2f i) : SV_Target
			{
				float4 farcolor = hueshift(_FarColor, _FarHueShift);

				float farMin = _FarMinFalloff * i.objectSize;
				float farMax = max(_FarMaxFalloff * i.objectSize, farMin + 0.0001);	// add offset to prevent min==max z-fighting
				float farfalloff = 1.0 - smoothstep(farMin, farMax, i.distFromPoint);
				farcolor.a *= farfalloff * _FarOpacity;

				if (_OverlayType == 2)
					return farcolor;

				float depth = calculateCameraDepth(i.projPos.xy, i.rayFromCamera, rcp(i.vertex.w));

				if (_NearMinFalloff > _NearMaxFalloff)
					if (depth > _Range)
						discard;

				float nearMin = _NearMinFalloff * i.objectSize;
				float nearMax = max(_NearMaxFalloff * i.objectSize, nearMin + 0.0001);
				float nearfalloff = 1 - smoothstep(nearMin, nearMax, depth);
				float4 nearcolor = hueshift(_NearColor, _NearHueShift) * nearfalloff;
				nearcolor.a *= _NearOpacity;

				if (_OverlayType == 1)
					return nearcolor;

				float4 c = 0;
				c.rgb = nearcolor.rgb * nearcolor.a + farcolor.rgb * farcolor.a * (1 - nearcolor.a);
				c.a = nearcolor.a + farcolor.a * (1 - nearcolor.a);

				return c;
			}
			ENDCG
		}
	}
}
