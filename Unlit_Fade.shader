// Copyright 2017 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

// Modified by:
// @andybak - Discord (Open Brush Team)
// Samuel Dresser - samdresser6@gmail.com 
// CultureVerse - https://cultureverse.org
// On August 6th, 2023 to include stroke effects. 

Shader "Brush/Special/Unlit_Fade_ModifiedWithTime" {
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
        _FadeAmount ("Fade Amount", Range(0,1)) = 1
        _ClipStart ("Clip Start", Float) = 0
        _ClipEnd ("Clip End", Float) = 1
        _BrushFeatherSig("Brush Feather Sig", Float) =0.1

    }

    SubShader {
        Pass {
            Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
            Lighting Off
            Cull Off

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile __ TBT_LINEAR_TARGET
            #pragma multi_compile_fog
            #include "../../../Shaders/Include/Brush.cginc"
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float _Cutoff;
            float _FadeAmount;

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float4 color : COLOR;
                float4 texcoord2 : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                float clipinfo : TEXCOORD1;
                float4 color : COLOR;
                UNITY_FOG_COORDS(1)

                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata_t v)
            {
                v2f o;
            
                UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert


                float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
                //o.clipinfo = i.texcoord2.w;

                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord.xy = v.texcoord;
                o.clipinfo = completon;
                o.color = TbVertToNative(v.color);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c;
                UNITY_APPLY_FOG(i.fogCoord, i.color);
                c = tex2D(_MainTex, i.texcoord.xy) * i.color;

                float completion = CalcFeather(i.clipinfo, c.a);
                c*=completion;
                if (c.a < _Cutoff) {
                    discard;
                }
                c.a *= _FadeAmount; // Apply the fade effect to the alpha channel
                return c;
            }

            ENDCG
        }
    }
    
    Fallback "Unlit/Diffuse"
}