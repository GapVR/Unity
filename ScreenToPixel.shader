//************************************************************/
//**                 ╔═╗                                    **/
//**   ▒▒▒▒▒▒▒▒      ╚═╝        ╔═╗╔═══╗╔═╗░░░░░░░░╔═╗░░░░░ **/
//**  ▒▒▒▒▒▒▒░░ ╔════╗═╗═╗╔═╗═══╣ ║║ □ ║║ ║════╗═══╣ ║╔═╗ ░ **/
//** ▓▓▓▓▓▓▓░░░ ║ ╔═╗║ ║╗╚╝╔╝ □ ║ ║║  ═╩╣ ║╔═╗ ║ ╔═╝ ╚╝╔╝ ░ **/
//** ▓▓▓▓▓▓▓░░░ ║ ╚═╝║ ║╝╔╗╚╗ ══╣ ║║ □  ║ ║╚═╝ ║ ╚═╗ ╔╗╚╗ ░ **/
//** ▓▓▓▓▓▓▓░░░ ║ ╔══╝═╝═╝╚═╩═══╩═╝╚════╝═╝════╝═══╝═╝╚═╝ ░ **/
//** ▓▓▓▓▓▓▓░░  ║ ║   copyright (c) 2024-2026 ぎん（Gin）   ░░░ **/
//** ▓▓▓▓▓▓▓░   ╚═╝░░░░░░░░░░░░░░░░░░░░░░www2.booth.pm░░░   **/
//**                                                        **/
//**    ScreenToPixel.shader (for "pixelBlock" accessory)   **/
//**      v0.4 2026/05/28  -  dither bandpass & contrast    **/
//**      v0.3 2025/08/07  -  LUT & dithermap               **/
//**      v0.2 2025/03/26  -  initial release               **/
//**      v0.1 2024/11/24  -  prototype                     **/
//**                                                        **/
//************************************************************/

// This source code is licenced under the pixelBlock Terms of Use.
// Subject to personal, non-commercial use only.
// Product page: https://www2.booth.pm/items/6790541

Shader "VOIDKoubou/ScreenToPixel"
{
	Properties
	{
		[Header(Decoration)]
		_FadeMin ("Fade Min", Float) = 0.06
		_FadeLength ("Fade Length", Float) = 0.1
		_DisplayAngle ("Display Angle", Range(0, 1)) = 0.7

		_MainTex ("Texture", 2D) = "black" {}
		_MaskTex ("Mask", 2D) = "black" {}

		[Header(Image)]
		_Res ("Resolution [0: disable]", Int) = 48
		_Saturation ("Saturation", Float) = -2.0
		_Contrast ("Contrast", Float) = 1.0
//		_StepSize ("Step Size", Range( -1, 1)) = 1	// step size, retired

		[Header(Dithering)]
		[ToggleUI] _DitherEnable ("Enable Dithering", Int) = 1
		_DitherTex ("Dither Map", 2D) = "grey" {}

		[Header(Colours)]
		_Colours ("Bits per Channel [0: disabled]", Float) = 16

		[Header(LUT Palette)]
		_LUTIndex ("Palette Index [0: disabled]", Range(0,255)) = 0
		[ToggleUI] _LUTInterpolate ("Trilinear Filtering", Int) = 0
		_LUTAtlas ("LUT Atlas", 3D) = "" {}
		_LUTAtlasCount ("Atlas Palette Count", Int) = 1

		[Header(Camera Mode)]
		[Enum(Off, 0, On, 1)] _CameraEnable ("Enable Camera Mode", Int) = 1

		[Header(Rendering)]
		[Enum(Off, 0, On, 1)] _ZWrite ("ZWrite", Int) = 0
	}

	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent+999" }
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
//			float _StepSize;	// step size, retired
			float _FadeMin;
			float _FadeLength;
			float _DisplayAngle;

			float _Saturation;
			float _Contrast;
			float _Colours;

			int _CameraEnable;
			float _VRChatCameraMode;	// 0 normal, 1 VR cam, 2 Desktop cam, 3 screenshot

			bool isCam()
			{
				return ((_CameraEnable != 0) && ((_VRChatCameraMode == 1) || (_VRChatCameraMode == 2)));
			}

			v2f vert (appdata v)
			{
				bool cameraMode = isCam();

				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.uv2 = v.uv2;
				// o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;	// vertex pos
				o.worldPos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;	// mesh origin pos
				if ((cameraMode) && (length(_WorldSpaceCameraPos - o.worldPos) <= (_FadeMin + _FadeLength)))
				{
					o.vertex = float4(v.vertex.x*2, -v.vertex.y*2, 1, 1);
				}
				o.dotproduct = dot(normalize(v.normal), normalize(ObjSpaceViewDir(v.vertex)));
				return o;
			}

			int _DitherEnable;
			sampler2D _DitherTex;
			float4 _DitherTex_TexelSize;	// float4(1/width, 1/height, width, height)

// palette & interpolation functions

			float _LUTIndex;
			int _LUTInterpolate;
			sampler3D _LUTAtlas;
			float4 _LUTAtlas_TexelSize;	// float(1/width, 1/height, 1/depth, depth)
			int _LUTAtlasCount;	// use slider, retired

			float paletteSize;
			float paletteOffset;
			float paletteDepth;

			float3 saturateColour (float3 col, float sat)
			{
				float relLumi;
				if (_LUTIndex > 0)
					relLumi = dot(col, float3(0.299, 0.587, 0.114));	// use standard luma
				else
					relLumi = dot(col, float3(0.4, 0.51, 0.114));	// use custom luma
				return lerp(float3(relLumi, relLumi, relLumi), col, sat);
			}

			float3 Atlas3D(float3 col)
			{
				float3 texelUVW = float3(col.xy, (col.z * (paletteSize - 1) + paletteOffset + 0.5)/paletteDepth);
				return tex3D(_LUTAtlas, texelUVW).rgb;
			}

			float3 Atlas3DTrilinear(float3 col)	// 8 samples & 7 lerps
			{
				float x = col.x * paletteSize;
				float y = col.y * paletteSize;
				float zoff = col.z * (paletteSize - 1);

				float x0 = floor(x - 0.5) + 0.5;
				float y0 = floor(y - 0.5) + 0.5;
				float x1 = min(x0 + 1, paletteSize - 0.5);
				float y1 = min(y0 + 1, paletteSize - 0.5);

				float z0 = floor(zoff);
				float z1 = min(z0 + 1, paletteSize - 1);

				float weightx = saturate(x - x0);
				float weighty = saturate(y - y0);
				float weightz = zoff - z0;

				float2 uv00 = float2(x0, y0) * _LUTAtlas_TexelSize.x;
				float2 uv01 = float2(x0, y1) * _LUTAtlas_TexelSize.x;
				float2 uv10 = float2(x1, y0) * _LUTAtlas_TexelSize.x;
				float2 uv11 = float2(x1, y1) * _LUTAtlas_TexelSize.x;

				float palette0 = (paletteOffset + z0 + 0.5)/paletteDepth;
				float palette1 = (paletteOffset + z1 + 0.5)/paletteDepth;

				float3 c000 = tex3D(_LUTAtlas, float3(uv00, palette0)).rgb;
				float3 c001 = tex3D(_LUTAtlas, float3(uv00, palette1)).rgb;
				float3 c010 = tex3D(_LUTAtlas, float3(uv01, palette0)).rgb;
				float3 c011 = tex3D(_LUTAtlas, float3(uv01, palette1)).rgb;
				float3 c100 = tex3D(_LUTAtlas, float3(uv10, palette0)).rgb;
				float3 c101 = tex3D(_LUTAtlas, float3(uv10, palette1)).rgb;
				float3 c110 = tex3D(_LUTAtlas, float3(uv11, palette0)).rgb;
				float3 c111 = tex3D(_LUTAtlas, float3(uv11, palette1)).rgb;

				float3 c00 = lerp(c000, c001, weightz);
				float3 c01 = lerp(c010, c011, weightz);
				float3 c10 = lerp(c100, c101, weightz);
				float3 c11 = lerp(c110, c111, weightz);
				float3 c0 = lerp(c00, c10, weightx);
				float3 c1 = lerp(c01, c11, weightx);
				return lerp(c0, c1, weighty);
			}

// MAIN

			float4 frag (v2f i ) : SV_Target
			{
				bool cameraMode = isCam();

				float4 mainCol = tex2D(_MainTex, i.uv.xy);

				float distanceFromCamera = length(_WorldSpaceCameraPos - i.worldPos);
				if (distanceFromCamera <= (_FadeMin + _FadeLength))
				{
					if (((length(tex2D(_MaskTex, i.uv.xy).rgb - float3(0,0,0).rgb) < 0.01) && (i.dotproduct > _DisplayAngle)) || (cameraMode))
					{
						float4 c;
						float2 uv2 = i.uv2;

						#ifdef USING_STEREO_MATRICES
							uv2.x *= 0.5;
						#endif

// screen aspect ratio & pixellation

						float2 aspectRes = float2(_Res, _Res);
						float2 ditherRes = aspectRes;

						if (cameraMode)
							aspectRes.x *= _ScreenParams.x/_ScreenParams.y;

						float2 pixelCoord;

						if (_Res > 0)
						{
							pixelCoord = floor(uv2 * aspectRes);
							c = tex2D(_GrabTexture, pixelCoord/aspectRes);
						}
						else
						{
							ditherRes = _ScreenParams.xy;	// fix for dithering when _Res = 0
							pixelCoord = uv2 * ditherRes;
							c = tex2D(_GrabTexture, uv2);
						}

// step size, retired
//						c *= step(cos((uv2.x * aspectRes.x * 2) * UNITY_PI), _StepSize);
//						c *= step(cos((uv2.y * aspectRes.y * 2) * UNITY_PI), _StepSize);

						c = lerp(mainCol, c, saturate(c.a));

// meat

	// saturate
						c.rgb = saturate(saturateColour(c.rgb, _Saturation));

	// constrast
						// c.rgb = saturate((c.rgb - 0.5) * _Contrast + 0.5);
						c.rgb = saturate(c.rgb * exp2(_Contrast));

	// prepare dithering
						float threshold = 0.01;		// bandpass cutoff %

						float ditherValue = 0.5;	// fallback to hard B/W if no dither
						if (_DitherEnable)
						{
							float2 ditherCoord = fmod(pixelCoord + 0.5, float2(_DitherTex_TexelSize.z, _DitherTex_TexelSize.w));
							float2 ditherUV = ditherCoord * float2(_DitherTex_TexelSize.x, _DitherTex_TexelSize.y);
							ditherValue = tex2D(_DitherTex, ditherUV).a;
						}

	// dithering
						// v0.4: added bandpass (applied to blacks then whites)
						threshold = threshold * _DitherEnable;
						if ((_Colours > 0.5) && (_Colours < 1.1))	// monochrome
						{
							float lumi = dot(c.rgb, float3(0.299, 0.587, 0.114));	// use standard luma

							float highpass = step(lumi, threshold);
							float lowpass = step(1 - threshold, lumi);

							c.rgb = step(ditherValue, lumi);
							c.rgb = lerp(c.rgb, 0, highpass);
							c.rgb = lerp(c.rgb, 1, lowpass);
						}
						else if (_Colours >= 1.1)	// RGB
						{
							float quantDither = (ditherValue - 0.5) / (_Colours - 1);

							float3 highpass = step(c.rgb, threshold);
							float3 lowpass = step(1 - threshold, c.rgb);

							c.rgb = floor((c.rgb + quantDither) * (_Colours - 1) + 0.5) / (_Colours - 1);
							c.rgb = lerp(c.rgb, 0, highpass);
							c.rgb = lerp(c.rgb, 1, lowpass);
						}

	// apply palette & interpolation
						if (_LUTIndex > 0)
						{
							paletteSize = 1/_LUTAtlas_TexelSize.x;
							paletteOffset = (round(1 + (_LUTIndex - 1) * (_LUTAtlasCount - 1) / (255 - 1)) - 1) * paletteSize;
							paletteDepth = paletteSize * _LUTAtlasCount;

							c.rgb = saturate(c.rgb);

							if (_LUTInterpolate > 0)
								c.rgb = Atlas3DTrilinear(c.rgb);
							else
								c.rgb = Atlas3D(c.rgb);
						}

	// desaturation, retired
						// c.rgb = saturate(saturateColour(c.rgb, 1/(1+((_Saturation-1)*0.618))));

// end meat

						c.a = 1;

						if (cameraMode)
						{
							return c;
						}
						else
						{
							float fadeFactor = saturate((distanceFromCamera - _FadeMin)/_FadeLength);
							return lerp(c, mainCol, fadeFactor);
						}
					}
				}

				return mainCol;
			}
			ENDCG
		}
	}
}
