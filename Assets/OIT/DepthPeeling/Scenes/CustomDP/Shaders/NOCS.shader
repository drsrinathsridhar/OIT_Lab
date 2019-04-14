Shader "Common/NOCS"
{
	Properties
	{
		_NormalizationFactor ("Normalization Factor", float) = 1.0
	}


	SubShader
	{
		Tags
		{
			"RenderType" = "Opaque"
			"DisableBatching " = "True"
		}

		Pass
		{
			Cull Off
			Lighting Off

			CGPROGRAM
	#pragma vertex vert
	#pragma fragment frag
	#include "UnityCG.cginc"

			struct v2f
			{
				float4 pos : SV_POSITION;
				float4 NOCSPos : TEXCOORD1;
			};

			float _NormalizationFactor;

			v2f vert(appdata_full v)
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.NOCSPos = v.vertex;
				return o;
			}

			float4 frag(v2f i) : COLOR
			{
				// Unity uses left-handed coordinates, but NOCS is right-handed. So flip.
				i.NOCSPos = float4(-i.NOCSPos[0], i.NOCSPos[1], i.NOCSPos[2], i.NOCSPos[3]);
				i.NOCSPos = i.NOCSPos / _NormalizationFactor;

		#if defined(SHADER_API_D3D9) || defined(SHADER_API_D3D11) || defined(SHADER_API_D3D11_9X) // DirectX
				// Direct3D-like: The clip space depth goes from 0.0 at the near plane to +1.0 at the far plane. This applies to Direct3D, Metal and consoles.
				i.NOCSPos = i.NOCSPos + 0.5; // Offset to corner
		#else
				// OpenGL-like: The clip space depth goes from –1.0 at the near plane to +1.0 at the far plane. This applies to OpenGL and OpenGL ES.
				i.NOCSPos = i.NOCSPos + 1.0; // Offset to corner
				i.NOCSPos /= 2.0;
		#endif

				//if (i.NOCSPos[0] > 1.0 || i.NOCSPos[1] > 1.0 || i.NOCSPos[2] > 1.0
				//	|| i.NOCSPos[0] < 0.0 || i.NOCSPos[1] < 0.0 || i.NOCSPos[2] < 0.0)
				//{
				//	i.NOCSPos[0] = 1.0;
				//	i.NOCSPos[1] = 1.0;
				//	i.NOCSPos[2] = 1.0;
				//	i.NOCSPos[3] = 0.0;
				//}

				return i.NOCSPos;
			}
			ENDCG
		}
	}
		FallBack "Diffuse"
}