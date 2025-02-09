Shader "Custom/VoronoiCrystal"
{
	Properties
	{
		_Scale ("Scale", Float) = 10.0
		_Color1 ("Color 1", Color) = (0.9, 0.9, 0.9, 1)
		_Color2 ("Color 2", Color) = (0.6, 0.6, 0.6, 1)
		_Color3 ("Color 3", Color) = (0.3, 0.3, 0.3, 1)
		_Color4 ("Color 4", Color) = (0.1, 0.1, 0.1, 1)
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _Scale;
			fixed4 _Color1;
			fixed4 _Color2;
			fixed4 _Color3;
			fixed4 _Color4;

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

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv * _Scale;
				return o;
			}

			// hash22 from Hash without Sine (2014-09-01) by Dave_Hoskins
			// https://www.shadertoy.com/view/4djSRW
			float2 hash22(float2 p)
			{
				float3 p3 = frac(float3(p.xyx) * float3(.1031, .1030, .0973));
				p3 += dot(p3, p3.yzx+33.33);
				return frac((p3.xx+p3.yz)*p3.zy);
			}

			// Reference: Voronoi noises (2013-12-31) by Pietro De Nicola
			// https://www.shadertoy.com/view/lsjGWD
			fixed4 frag (v2f i) : SV_Target
			{
				float2 uv = i.uv;

				fixed4 col = fixed4(0,0,0,0);
				float minDist = 1.0;
				float2 nearest = float2(0, 0);

				float2 iuv = floor(uv);
				float2 fuv = frac(uv);

				for (int y = -1; y <= 1; y++)
				{
					for (int x = -1; x <= 1; x++)
					{
						float2 neighbor = float2(x, y);
						float2 this = hash22(iuv + neighbor);

						this = 0.5 + 0.5 * sin(_Time.y + 6.2831 * this);

						float2 diff = neighbor + this - fuv;
						float dist = length(diff);

						if (dist < minDist)
						{
							minDist = dist;
							nearest = this;
						}
					}
				}

				float nearestcol = nearest.x;

				if (nearestcol < 0.25)
					col = _Color1;
				else if (nearestcol < 0.5)
					col = _Color2;
				else if (nearestcol < 0.75)
					col = _Color3;
				else
					col = _Color4;

				return col;
			}
			ENDCG
		}
	}
}