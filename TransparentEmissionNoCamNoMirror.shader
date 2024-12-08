// TransparentEmissionNoCamNoMirror
// v0.1 240908 https://github.com/GapVR

Shader "VOIDKoubou/TransparentEmissionNoCamNoMirror"
{
	Properties
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_EmissionTex("Emission (RGB)", 2D) = "black" {}
		_EmissionIntensity("Emission Intensity", Range(0, 10)) = 1
		[KeywordEnum(Off, Front, Back)] _Cull("Culling", Float) = 2
	}
	SubShader
	{
		Tags { "RenderType"="Transparent" "Queue"="Transparent" }
		LOD 200
		Blend SrcAlpha OneMinusSrcAlpha
		Cull [_Cull]

		CGPROGRAM
		#pragma surface surf Lambert alpha:fade
		#pragma shader_feature _CULL_OFF _CULL_FRONT _CULL_BACK

		sampler2D _MainTex;
		sampler2D _EmissionTex;
		fixed4 _Color;
		float _EmissionIntensity;

		float _VRChatCameraMode;
		// uint _VRChatCameraMask;
		float _VRChatMirrorMode;
		// float3 _VRChatMirrorCameraPos;

		struct Input
		{
			float2 uv_MainTex;
			float2 uv_EmissionTex;
		};

		void surf (Input IN, inout SurfaceOutput o)
		{
			if ((_VRChatCameraMode > 0) || (_VRChatMirrorMode > 0))
				discard;

			fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
			fixed4 emission = tex2D(_EmissionTex, IN.uv_EmissionTex) * _EmissionIntensity;
			o.Albedo = c.rgb;
			o.Alpha = c.a;
			o.Emission = emission.rgb;
		}
		ENDCG
	}
	FallBack "Diffuse"
}