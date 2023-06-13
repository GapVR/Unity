Shader "VOIDKoubou/EMFReaderLED"
{
	Properties
	{
	}

	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"Queue" = "Geometry"
		}

		Cull Off

		CGPROGRAM

		#include "UnityPBSLighting.cginc"
		#include "UnityShaderVariables.cginc"
		#include "UnityCG.cginc"
		#pragma target 3.0
		#pragma surface surf NoLighting noambient
		#pragma multi_compile _ VERTEXLIGHT_ON

		struct Input
		{
			float2 uv_texcoord;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
		};

		fixed4 LightingNoLighting(SurfaceOutput s, fixed3 lightDir, fixed atten)
		{
			return fixed4(s.Albedo, s.Alpha);
		}

		void GetBestLights( inout int LightType, inout int orificeType, inout float3 orificePositionTracker, inout float3 orificeNormalTracker, inout float3 penetratorPositionTracker, inout float penetratorLength ) {
			float ID = step( 0.5 , 0 );
			float baseID = ( ID * 0.02 );
			float holeID = ( baseID + 0.01 );
			float ringID = ( baseID + 0.02 );
			float normalID = ( 0.05 + ( ID * 0.01 ) );
			float penetratorID = ( 0.09 + ( ID * -0.01 ) );
			float4 orificeWorld;
			float4 orificeNormalWorld;
			float4 penetratorWorld;
#ifdef VERTEXLIGHT_ON
			for (int i=0;i<4;i++) {
				float range = (0.005 * sqrt(1000000 - unity_4LightAtten0[i])) / sqrt(unity_4LightAtten0[i]);
				if (length(unity_LightColor[i].rgb) < 0.01) {
					if (abs(fmod(range,0.1)-holeID)<0.005) {
						LightType = 1;
						orificeType=0;
						orificeWorld = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						orificePositionTracker = mul( unity_WorldToObject, orificeWorld ).xyz;
					}
					if (abs(fmod(range,0.1)-ringID)<0.005) {
						LightType = 2;
						orificeType=1;
						orificeWorld = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						orificePositionTracker = mul( unity_WorldToObject, orificeWorld ).xyz;
					}
					if (abs(fmod(range,0.1)-normalID)<0.005) {
						LightType = 3;
						orificeNormalWorld = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						orificeNormalTracker = mul( unity_WorldToObject, orificeNormalWorld ).xyz;
					}
					if (abs(fmod(range,0.1)-penetratorID)<0.005) {
						LightType = 4;
						float3 tempPenetratorPositionTracker = penetratorPositionTracker;
						penetratorWorld = float4(unity_4LightPosX0[i], unity_4LightPosY0[i], unity_4LightPosZ0[i], 1);
						penetratorPositionTracker = mul( unity_WorldToObject, penetratorWorld ).xyz;
						if (length(penetratorPositionTracker)>length(tempPenetratorPositionTracker)) {
							penetratorPositionTracker = tempPenetratorPositionTracker;
						} else {
							penetratorLength=unity_LightColor[i].a;
						}
					}
				}
			}
#endif
		}

		void surf( Input i , inout SurfaceOutput  o )
		{
			float orificeType = 0;
			float3 orificePositionTracker = float3(0,0,100);
			float3 orificeNormalTracker = float3(0,0,99);
			float3 penetratorPositionTracker = float3(0,0,1);
			float pl=0;
			int LightType=0;
			GetBestLights(LightType, orificeType, orificePositionTracker, orificeNormalTracker, penetratorPositionTracker, pl);

			float distanceToOrifice = length( orificePositionTracker );
			float distanceToNormal = length( orificeNormalTracker );
			float distanceToPenetrator = length( penetratorPositionTracker );

			float closest;
			if ((distanceToOrifice > 0) && (distanceToOrifice < 1000))
				closest = distanceToOrifice;
			if ((distanceToNormal > 0) && (distanceToNormal < 1000))
				closest = min(closest,distanceToNormal);
			if ((distanceToPenetrator > 0) && (distanceToPenetrator < 1000))
				closest = min(closest,distanceToPenetrator);

			if (LightType > 0)
			{
				if (closest < 1)
					o.Albedo = lerp(float3(1.0,0.1,0.1),float3(0.1,1.0,0.1),saturate(tan(_Time*33)));
				else
					o.Albedo = lerp(float3(1.0,0.1,0.1),float3(0.1,1.0,0.1),saturate((distanceToOrifice-2)/29.0));
			}
			else
			{
				o.Albedo = float3(0.06,0.07,0.05);
			}
		}
		ENDCG
	}
}
