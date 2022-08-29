Shader "Hasan/Toon shader"
{
	Properties//'Variable fields' that appear on the inspector of the material that is using the shader.
	{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Main Texture", 2D) = "white" {}
		// Ambient light is applied uniformly to all surfaces on the object.
		[HDR]//HDR attribute, allows the r,b,g values of a colour to be set in a bigger range than the regular 0-1, while the screen can't render values outside 0-1, a greater value can be used for different rendering effects...///////////////////
		_AmbientCol("Ambient Color", Color) = (0.4,0.4,0.4,1)//Used to create ambient lighting ('second hand light' that has reflected off multiple surfaces). //////Changed

		[HDR]
		_SpecularCol("Specular Color", Color) = (0.9,0.9,0.9,1)//This controls the colour of reflection from specular lighting./////Changed
		

		_GlossAmount("GlossAmount", Float) = 32////Changed

		_RimLevel("Rim Level", Range(0, 1)) = 0.716/////Changed
		[HDR] 
		_RimCol("Rim Col", Color) = (1,1,1,1)/////Changed
		
		_RimThresh("Rim Thresh", Range(0, 1)) = 0.1//This controls the smooth transition to the rim//////Changed		
	}
	SubShader//Contains the code that we write for our shader. A shader can have multiple SubShaders each containing different configurations depending for different hardware trying to use the shader.
	{
		Pass//A subshader can contain multiple passes. Code can be 'split' within passes, and only run depending on the requirements of the machine trying to use the shader.
		{
		
			Tags//Tags are key-value pairs that determine how and when to actually render the pass.
			{
				"LightMode" = "ForwardBase"
				"PassFlags" = "OnlyDirectional"
			}

			CGPROGRAM//Starting point of our actual shader code.
			#pragma vertex vert//Created a vetex shader called 'vert'.
			#pragma fragment frag//Created a fragment shader called 'frag'.
			
			#pragma multi_compile_fwdbase//Depending on the lighting settings, multiple versions of this shader will compile.
			
			#include "UnityCG.cginc"//#include Allows us to used functions from a unity librabry.////////////////////////////
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			struct appdata//appdata contains all of the information about our mesh that we need to use. Each vertex has its own copy of each of the variables in this struct 
			{
				float4 vertex : POSITION;				
				float4 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};

			struct v2f//Vertex to fragment, gets info from our vertex shader, and translates it into info for the fragment shader.
			{
				float4 pos : SV_POSITION;//Semantics keywords tell the program in which way to consider a variable. 'SV_POSITION' is screen space coordinates.
				float3 worldNormal : NORMAL;//'NORMAL' is the vertex's normal.
				float2 uv : TEXCOORD0;//'TEXCOORD0' is the first UV coordinate of the vertex.
				float3 viewDir : TEXCOORD1;//Second UV coordinate of the vertex.	
				// Macro found in Autolight.cginc. Declares a vector4
				// into the TEXCOORD2 semantic with varying precision 
				// depending on platform target.
				SHADOW_COORDS(2)//
			};

			sampler2D _MainTex;//Texture variable for the shader to use in some way. Each property created at the top needs a corresponding variable.
			float4 _MainTex_ST;//Gets our property's information that we need.
			
			v2f vert (appdata v)//Vertex shader, runs on every vertex, calculations are done for the vertex so it can be used by the fragment shader.
			{
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);//Transforms the point from object space to cameras clip space.
				o.worldNormal = UnityObjectToWorldNormal(v.normal);//Transforms the normal of the vertex from object space to world space.		
				o.viewDir = WorldSpaceViewDir(v.vertex);//Function returns the world space direction towards the camera.
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				// Defined in Autolight.cginc. Assigns the above shadow coordinate
				// by transforming the vertex from world space to shadow-map space.
				TRANSFER_SHADOW(o)
				return o;
			}
			
			float4 _Color;      //Variables made corresponding to the properties made at the top.
								
			float4 _AmbientCol;	//Variables made corresponding to the properties made at the top.
								
			float4 _SpecularCol;//Variables made corresponding to the properties made at the top.
			float _GlossAmount;	//Variables made corresponding to the properties made at the top.	
								
			float4 _RimCol;		//Variables made corresponding to the properties made at the top.
			float _RimLevel;	//Variables made corresponding to the properties made at the top.
			float _RimThresh;	//Variables made corresponding to the properties made at the top.

			float4 frag (v2f i) : SV_Target//Fragment shader, actually renders each vertex on the screen. "SV_Target" is the semantic for the fragment shader colour output.
			{
				float3 normal = normalize(i.worldNormal);
				float3 viewDir = normalize(i.viewDir);

				// Calculate illumination from directional light.
				// _WorldSpaceLightPos0 is a vector pointing the OPPOSITE
				// direction of the main directional light.
				float NdotL = dot(_WorldSpaceLightPos0, normal);//Getting dot product between the normal and the light source, a value we will use to calculate light reflection./////Changed

				
				float shadow = SHADOW_ATTENUATION(i);//Sampling the shadow map.
				
				float lightIntensity = smoothstep(0, 0.01, NdotL * shadow);	//We make it so there is a smooth transition between light to dark.

				float4 light = lightIntensity * _LightColor0; //Times the colour with the light intensity to get the final 'light value'.

				// Calculate specular reflection.
				float3 halfVector = normalize(_WorldSpaceLightPos0 + viewDir);
				float NdotH = dot(normal, halfVector);
				// Multiply _GlossAmount by itself to allow artist to use smaller
				// glossiness values in the inspector.
				float specularIntensity = pow(NdotH * lightIntensity, _GlossAmount * _GlossAmount);
				float specularIntensitySmooth = smoothstep(0.005, 0.01, specularIntensity);
				float4 specular = specularIntensitySmooth * _SpecularCol;				

				// Calculate rim lighting.
				float rimDot = 1 - dot(viewDir, normal);
				// We only want rim to appear on the lit side of the surface,
				// so multiply it by NdotL, raised to a power to smoothly blend it.
				float rimIntensity = rimDot * pow(NdotL, _RimThresh);
				rimIntensity = smoothstep(_RimLevel - 0.01, _RimLevel + 0.01, rimIntensity);
				float4 rim = rimIntensity * _RimCol;

				float4 sample = tex2D(_MainTex, i.uv);

				return (light + _AmbientCol + specular + rim) * _Color * sample;
			}
			ENDCG//Ending point of our actual shader code.
		}
	}
}