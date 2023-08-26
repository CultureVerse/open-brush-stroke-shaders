// Modified by:
// @andybak - Discord (Open Brush Team)
// Samuel Dresser - samdresser6@gmail.com 
// CultureVerse - https://cultureverse.org
// On August 6th, 2023 to include stroke effects. 

Shader "Brush/StandardDoubleSided_Stroke_Modified" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 0)
        _Shininess ("Shininess", Range (0.01, 1)) = 0.078125
        _MainTex ("Base (RGB) TransGloss (A)", 2D) = "white" {}
        _BumpMap ("Normalmap", 2D) = "bump" {}
        _AlbedoFadeColor("Albedo Fade Color", Color) = (0,0,0,0)
        _AlbedoFadeEdgeLength("Albedo Fade Edge Width", Float) = 0.001
        _AlbedoFadeEdgePower("Albedo Fade Edge Power", Float) = 1
        
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _ClipStart ("Clip Start", Float) = 0
        _ClipEnd ("Clip End", Float) = 1
        _BrushFeatherSig("Brush Feather Sig", Float) =0.1
        _AlphaLerp("Alpha Lerp Mult", Float) = 1
    }

    SubShader {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        LOD 400
        Cull Off
        Blend SrcAlpha OneMinusSrcAlpha
        ColorMask RGB

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile __ AUDIO_REACTIVE
            #pragma multi_compile __ TBT_LINEAR_TARGETs

            #include "../../../Shaders/Include/Brush.cginc"
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_BumpMap : TEXCOORD1;
                fixed4 color : COLOR;
                float3 uv2 : TEXCOORD2;
                float completion : TEXCOORD3;

                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float2 uv_MainTex : TEXCOORD0;
                float2 uv_BumpMap : TEXCOORD1;
                fixed4 color : COLOR;
                float3 uv2 : TEXCOORD2;
                float completion : TEXCOORD3;
                float4 vertex : SV_POSITION;

                UNITY_VERTEX_OUTPUT_STEREO
            };

            sampler2D _MainTex;
            sampler2D _BumpMap;
            fixed4 _Color;
            half _Shininess;
            float _Cutoff;
            uniform float4 _LightColor0;

            uniform float4 _AlbedoFadeColor;
            uniform float _AlbedoFadeEdgeLength;
            uniform float _AlbedoFadeEdgePower;
            uniform  float _AlphaLerp;
            
            v2f vert (appdata v) {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv_MainTex = v.uv_MainTex;
                o.uv_BumpMap = v.uv_BumpMap;
                o.color = v.color;
                o.uv2 = v.uv2;
                o.completion = invLerp(v.uv2.x, v.uv2.y, v.uv2.z);
                return o;
            }

            float safepow(float infloat, float exp)
            {
                return sign(infloat)*pow(abs(infloat), exp);
            }

            fixed4 frag (v2f i) : SV_Target {
                // Normals & lighting
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv_BumpMap)) * 2 - 1;

                fixed3 lightDirection = normalize(_WorldSpaceLightPos0.xyz - i.vertex.xyz);
                fixed3 diffuseLight = max(0, dot(tangentNormal, lightDirection)) * _LightColor0.rgb;

                // Alpha test
                fixed4 mainTex = tex2D(_MainTex, i.uv_MainTex);
                clip(mainTex.a - _Cutoff);

                // Stroke completiom
                float preclamp;
                float completion = CalcFeather(i.completion, mainTex.a,  preclamp);
                
                
                clip(completion);

                preclamp /= _AlbedoFadeEdgeLength;
                float fadeEdge = (ceil(saturate(0.5-abs(0.5 - preclamp))));
                fadeEdge *=1-preclamp;
                fadeEdge = pow(fadeEdge, _AlbedoFadeEdgePower);

                fixed4 color = mainTex * _Color * i.color;
                color = lerp(color, _AlbedoFadeColor, fadeEdge);
                color.a *= _AlphaLerp;
                //color.a *= step(_ClipStart, i.completion+feather) * (1-step(_ClipEnd, i.completion+feather)); // Modify alpha channel based on completion
                return color;
            }
            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
}
