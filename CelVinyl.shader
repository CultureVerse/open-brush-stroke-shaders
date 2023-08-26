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

Shader "Brush/Special/CelVinyl_ModifiedWithTime" {
  Properties{
    _MainTex("MainTex", 2D) = "white" {}
    _Color("Color", Color) = (1,1,1,1)
    _Cutoff ("Alpha Cutoff", Range (0,1)) = 0.5
    _AlbedoFadeColor("Albedo Fade Color", Color) = (0,0,0,0)
    _AlbedoFadeEdgeLength("Albedo Fade Edge Width", Float) = 0.001
    _AlbedoFadeEdgePower("Albedo Fade Edge Power", Float) = 1
        
    _ClipStart ("Clip Start", Float) = 0
    _ClipEnd ("Clip End", Float) = 1
    _BrushFeatherSig("Brush Feather Sig", Float) =0.1

  }

  SubShader{
    Pass {
      Tags{ "Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}

      Lighting Off
      Cull Off

      CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile __ TBT_LINEAR_TARGET
        #pragma multi_compile_fog
        #include "../../../Shaders/Include/Brush.cginc"
        #include "UnityCG.cginc"
        #pragma target 3.0

        sampler2D _MainTex;
        float4 _MainTex_ST;
        fixed4 _Color;
        float _Cutoff;
      
        uniform float4 _AlbedoFadeColor;
        uniform float _AlbedoFadeEdgeLength;
        uniform float _AlbedoFadeEdgePower;

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
            float4 color : COLOR;
            float clipinfo : TEXCOORD1;

            UNITY_FOG_COORDS(2)

            UNITY_VERTEX_OUTPUT_STEREO
        };

        v2f vert (appdata_t v)
        {

          v2f o;

          UNITY_SETUP_INSTANCE_ID(v); //Insert
          UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
          UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert
          float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
          o.clipinfo = completon;

          o.vertex = UnityObjectToClipPos(v.vertex);
          o.texcoord = v.texcoord;
          o.color = TbVertToNative(v.color);
          UNITY_TRANSFER_FOG(o, o.vertex);
          return o;
        }

        fixed4 frag (v2f i) : SV_Target
        {
          fixed4 tex = tex2D(_MainTex, i.texcoord) * i.color;
          float preclamp;
          float completion = CalcFeather(i.clipinfo, tex.a, preclamp);
          tex*=completion;

          preclamp /= _AlbedoFadeEdgeLength;
          float fadeEdge = (ceil(saturate(0.5-abs(0.5 - preclamp))));
          fadeEdge *=1-preclamp;
          fadeEdge = pow(fadeEdge, _AlbedoFadeEdgePower);
          tex = lerp(tex, tex*_AlbedoFadeColor, fadeEdge);

          UNITY_APPLY_FOG(i.fogCoord, tex);

          
          // Discard transparent pixels.
          if (tex.a < _Cutoff) {
            discard;
          }
          return tex;
        }

      ENDCG
    }
  }

  Fallback "Unlit/Diffuse"
}