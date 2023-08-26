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

Shader "Brush/Special/Petal_ModifiedWithTime" {
  Properties{
    _SpecColor("Specular Color", Color) = (0.5, 0.5, 0.5, 0)
    _Shininess("Shininess", Range(0.01, 1)) = 0.3
    _MainTex("Base (RGB) TransGloss (A)", 2D) = "white" {}
    _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    _ClipStart ("Clip Start", Float) = 0
    _ClipEnd ("Clip End", Float) = 1
    _BrushFeatherSig("Brush Feather Sig", Float) =0.1

  }
  SubShader{
    Tags {"IgnoreProjector" = "True" "RenderType" = "Opaque"}
    Cull Off

    CGPROGRAM
      #pragma target 4.0
      #pragma surface surf StandardSpecular vertex:vert addshadow alphatest:_Cutoff
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ ODS_RENDER

      #include "../../../Shaders/Include/Brush.cginc"

      struct Input {
        float2 uv_MainTex;
        float4 color : Color;
        fixed vface : VFACE;
        float clipinfo;
      };
 
      half _Shininess;

      void vert(inout appdata_full i, out Input o) {
        UNITY_INITIALIZE_OUTPUT(Input, o);

        i.color = TbVertToNative(i.color);
        float completon = invLerp(i.texcoord2.x, i.texcoord2.y, i.texcoord2.z);
        o.clipinfo = completon;

      }

      void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
        // Fade from center outward (dark to light)
        float4 darker_color = IN.color;
        darker_color *= 0.6;
        float4 finalColor = lerp(IN.color, darker_color, 1- IN.uv_MainTex.x);

        float preclamp;
        float completion = CalcFeather(IN.clipinfo, 0,preclamp);
        
        float fAO = IN.vface == -1 ? .5 * IN.uv_MainTex.x : 1;
        o.Albedo = finalColor * fAO;
        o.Smoothness = _Shininess;
        o.Specular = _SpecColor * fAO;
        o.Alpha = completion;
      }
    ENDCG
  }
}
