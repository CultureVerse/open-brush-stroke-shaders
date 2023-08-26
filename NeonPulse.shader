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

Shader "Brush/Visualizer/WaveformPulse_ModifiedWithTime" {
Properties {
  _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
          _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

    SubShader {
    Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend One One
    Cull off ZWrite Off

    CGPROGRAM
    #pragma target 3.0
    #pragma surface surf StandardSpecular vertex:vert
    #pragma multi_compile __ AUDIO_REACTIVE
    #pragma multi_compile __ TBT_LINEAR_TARGET
    #include "../../../Shaders/Include/Brush.cginc"

    struct Input {
      float4 color : Color;
      float2 tex : TEXCOORD0;
      float clipinfo : TEXCOORD1;

      float3 viewDir;
      float3 worldNormal;

      INTERNAL_DATA
    };

    float _EmissionGain;

    void vert (inout appdata_full i, out Input o) {
      UNITY_INITIALIZE_OUTPUT(Input, o);
      o.color = TbVertToSrgb(o.color);
      o.tex = i.texcoord;
      float completon = invLerp(i.texcoord2.x, i.texcoord2.y, i.texcoord2.z);
      o.clipinfo = completon;

    }

    // Input color is srgb
    void surf (Input IN, inout SurfaceOutputStandardSpecular o) {
      o.Smoothness = .8;
      o.Specular = .05;
      float audioMultiplier = 1;
#ifdef AUDIO_REACTIVE
      audioMultiplier += audioMultiplier * _BeatOutput.x;
      IN.tex.x -= _BeatOutputAccum.z;
      IN.color += IN.color * _BeatOutput.w * .25;
#else
      IN.tex.x -= _Time.x*15;
#endif
      IN.tex.x = fmod( abs(IN.tex.x),1);
      float neon = saturate(pow( 10 * saturate(.2 - IN.tex.x),5) * audioMultiplier);
      float4 bloom = bloomColor(IN.color, _EmissionGain);
      float3 n = WorldNormalVector (IN, o.Normal);
      half rim = 1.0 - saturate(dot (normalize(IN.viewDir), n));
      bloom *= pow(1-rim,5);

        float preclamp;
      float completion = CalcFeather(IN.clipinfo, 0,preclamp);
      o.Specular*=saturate(preclamp*5.0);
      o.Smoothness *=saturate(preclamp*5.0);
      o.Emission = SrgbToNative(bloom * neon)*saturate(preclamp*5.0);
    }
    ENDCG
    }
}
    