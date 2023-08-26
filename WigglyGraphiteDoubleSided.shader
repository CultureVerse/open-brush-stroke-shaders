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

Shader "Brush/Special/WigglyGraphiteDoubleSided_ModifiedWithTime" {
  Properties{
    _MainTex("Main Texture", 2D) = "white" {}
    _SecondaryTex("Diffuse Tex", 2D) = "white" {}
    _Cutoff("Alpha cutoff", Range(0,1)) = 0.5
      _ClipStart ("Clip Start", Float) = 0
   _ClipEnd ("Clip End", Float) = 1
   _BrushFeatherSig("Brush Feather Sig", Float) =0.1

  }
  SubShader{
    Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
    Cull Off

    CGPROGRAM
      #pragma target 3.0
      #pragma surface surf StandardSpecular vertex:vert alphatest:_Cutoff addshadow
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET

      #include "../../../Shaders/Include/Brush.cginc"
      #include "Assets/ThirdParty/Noise/Shaders/Noise.cginc"

      struct Input {
        float2 uv_MainTex;
        float4 color : Color;
        float2 texcoord1 : TEXCOORD1;
        fixed vface : VFACE;
        float clipinfo : TEXCOORD2;

      };

      sampler2D _MainTex;

      void vert(inout appdata_full i, out Input o) {
        UNITY_INITIALIZE_OUTPUT(Input, o);
        i.color = TbVertToSrgb(i.color);
        float completon = invLerp(i.texcoord2.x, i.texcoord2.y, i.texcoord2.z);
        o.clipinfo = completon;
      }

      void surf(Input IN, inout SurfaceOutputStandardSpecular o) {
        fixed2 scrollUV = IN.uv_MainTex;

        // Animate flipbook motion. Currently tuned to taste.
#ifdef AUDIO_REACTIVE
        float anim = ceil(fmod(_Time.y * 3.0 + _BeatOutput.x * 3.0, 6.0));
#else
        float anim = ceil(fmod(_Time.y * 12.0, 6.0));
#endif
        scrollUV.x += anim;
        scrollUV.x *= 1.1;


        float tex = tex2D(_MainTex, scrollUV).w;
        float preclamp;
        float completion = CalcFeather(IN.clipinfo, tex,preclamp);

        preclamp = min(preclamp*2.0, 5.0);
        o.Specular = 0;
        o.Smoothness = 0;
        o.Albedo = IN.color.rgb;
        o.Alpha =  tex* IN.color.a*preclamp;
        o.Normal.z *= IN.vface;
      }
    ENDCG
  }
  FallBack "Diffuse"
}
