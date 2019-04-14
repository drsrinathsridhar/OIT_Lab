Shader "Hidden/SDP/Init" 
{
	Properties 
	{
		_NormalizationFactor("Normalization Factor", float) = 1.0
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
			ZWrite On
			Cull Off
			Lighting Off

			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

			float _NormalizationFactor;
			
			struct a2v 
			{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f 
			{
				float4 pos : SV_POSITION;
				float4 NOCSPos : TEXCOORD1;
				float depth : TEXCOORD2;
			};

			struct PixelOutput 
			{
				fixed4 col : COLOR0;
				fixed4 depth : COLOR1;
			};
			
			v2f vert(a2v v) 
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.NOCSPos = v.vertex;
				o.depth = COMPUTE_DEPTH_01;
				
				return o;
			}
			
			PixelOutput frag(v2f i) : SV_Target 
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

				PixelOutput o;
				o.col = i.NOCSPos;
				o.depth = EncodeFloatRGBA(i.depth);
				return o;
			}
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}
