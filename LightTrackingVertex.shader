Shader "LightTrackingVertex"
{
	Properties
	{
		_Color ("Color", Color) = (1,1,1,1)
		_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Smoothness ("Smoothness", Range(0,1)) = 1.0
		_Metallic ("Metallic", Range(0,1)) = 0.0

		_MinDistance("Min Distance", Float) = 0.005
		_MaxDistance("Max Distance", Float) = 10
		_Cutoff("Cutoff", Float) = 1

		[Rendering]
		[Enum(UnityEngine.Rendering.CullMode)]
		_Cull("Cull", Float) = 0
	}
	SubShader
	{
		Tags
		{
			"RenderType" = "Transparent"
			"Queue"="Transparent-1"
		}

		ZWrite Off
		Blend One One
		Cull [_Cull]

		CGPROGRAM

		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"

		#pragma surface surf Standard vertex:vert alpha
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input
		{
			float2 uv_MainTex;
			float lightDist;
		};

		half _Smoothness;
		half _Metallic;
		fixed4 _Color;

		const float _MinDistance;
		const float _MaxDistance;
		const float _Cutoff;

		// all except #.#0, #.#5, #.#6
		void GetBestLight(inout float3 lightPosObj,inout float lightDist)
		{
			float4 lightPosWorld;
			for (int i=0;i<4;i++)
			{
				float range = (0.005 * sqrt(1000000 - unity_4LightAtten0[i])) / sqrt(unity_4LightAtten0[i]);
				if (length(unity_LightColor[i].rgb) < 0.01)
				{
					if ((abs(fmod(range,0.1)-0.02)<0.025) || (abs(fmod(range,0.1)-0.08)<0.015))
					{
						lightPosWorld = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						lightPosObj = mul(unity_WorldToObject, lightPosWorld).xyz;
						lightDist = length(lightPosObj);
						if (lightDist < _MinDistance)
						{
							lightDist = 999999;
							continue;
						}
					}
				}
			}
		}

		void vert(inout appdata_base v, out Input o)
		{
			const float3 origin = float3(0, 0, 0);

			float3 lightPosObj = origin;
			float lightDist = 0;
			GetBestLight(lightPosObj,lightDist);

			const float3 originB = float3(0,1,0);
			const float weightA = clamp(1 - v.texcoord.y, 0, 1);
			const float weightB = clamp(v.texcoord.y, 0, 1);
			const float3 boneALocalPosition = v.vertex.xyz - origin;
			const float3 boneBLocalPosition = v.vertex.xyz - originB;

			if (lightDist < _MinDistance && (lightDist < _MaxDistance || _MaxDistance == 0))
			{
				v.vertex = float4((boneALocalPosition + origin) * weightA + (boneBLocalPosition + lightPosObj) * weightB, 1);

				const float a = 2.1268;
				const float gravityAtten = (cosh(a * (weightB * 2 - 1)) / a - 2) * 0.001;
				const float3 gravityVector = mul((float3x3)unity_WorldToObject, originB);
				v.vertex += float4(gravityVector * gravityAtten, 0);
			}
			else
				v.vertex.xyz = origin;

			o.lightDist = lightDist;
			o.uv_MainTex = v.texcoord.xy;
		}

		void surf (Input IN, inout SurfaceOutputStandard o)
		{
			float fade = saturate(lerp(1,0, ((IN.lightDist - _MinDistance)/(_MaxDistance - _MinDistance))*_Cutoff));
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			o.Albedo = c.rgb;
			o.Metallic = _Metallic * fade;
			o.Smoothness = _Smoothness * fade;
			o.Alpha = c.a * fade;
		}
		ENDCG
	}
	FallBack "Diffuse"
}
