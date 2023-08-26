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

Shader "Brush/Special/Electricity_ModifiedWithTime" {
Properties {
  _MainTex ("Color", 2D) = "white" {}
  _DisplacementIntensity("Displacement", Float) = .1
    _EmissionGain ("Emission Gain", Range(0, 1)) = 0.5
    _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

CGINCLUDE
  #include "UnityCG.cginc"
  #include "../../../Shaders/Include/Brush.cginc"
  #include "Assets/ThirdParty/Noise/Shaders/Noise.cginc"

  struct appdata_t {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float3 normal : NORMAL;
    float3 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;
    float3 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
  UNITY_VERTEX_INPUT_INSTANCE_ID
  };

  sampler2D _MainTex;
  half _DisplacementIntensity;
  half _EmissionGain;

  struct v2f {
    float4 vertex : SV_POSITION;
    fixed4 color : COLOR;
    float2 texcoord : TEXCOORD0;
    float clipinfo : TEXCOORD1;
UNITY_VERTEX_OUTPUT_STEREO
  };

  float3 displacement(float3 pos, float mod) {
    // Noise
    float time = _Time.w;
    float d = 30;
    float freq = .1 + mod;
    float3 disp = float3(1,0,0) * curlX(pos * freq + time, d);
    disp += float3(0,1,0) * curlY(pos * freq + time, d);
    disp += float3(0,0,1) * curlZ(pos * freq + time, d);

    time = _Time.w*1.777;
    d = 100;
    freq = .2 + mod;
    float3 disp2 = float3(1,0,0) * curlX(pos * freq + time, d);
    disp2 += float3(0,1,0) * curlY(pos * freq + time, d);
    disp2 += float3(0,0,1) * curlZ(pos * freq + time, d);
    disp = disp * 3 + disp2 * 7;
    return disp;
  }


  v2f vertModulated (appdata_t v, float mod, float dir)
  {

    v2f o;
                    UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert
    float envelope = sin(v.texcoord0.x * (3.14159));
    float envelopePow =  (1-pow(1  - envelope, 10));
    v.color = TbVertToSrgb(v.color);

    float3 offsetFromMiddleToEdge_CS = v.texcoord1;
    float widthiness_CS = length(offsetFromMiddleToEdge_CS) / .02;
    float3 midpointPos_CS = v.vertex.xyz - offsetFromMiddleToEdge_CS;
    float3 disp = displacement(midpointPos_CS / widthiness_CS, mod);
    disp *= widthiness_CS;

    float waveform = 0;
#ifdef AUDIO_REACTIVE
    disp *= (_BeatOutput.x * 1 + .5);
    waveform = (tex2Dlod(_WaveFormTex, float4(v.texcoord0.x,0,0,0)).r - .5f);
    disp.y += waveform * .1;
    v.color = v.color*.5 + v.color*_BeatOutput.z*.5;
#endif
    // This recreates the standard ribbon position with some tapering at edges
    v.vertex.xyz = midpointPos_CS + offsetFromMiddleToEdge_CS * envelopePow;

    // This adds curl noise
    v.vertex.xyz += disp * _DisplacementIntensity * envelopePow;

    o.vertex = UnityObjectToClipPos(v.vertex);
    o.color = bloomColor(v.color, _EmissionGain);
    o.texcoord = v.texcoord0;
    float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
    o.clipinfo = completon;


    return o;
  }

  v2f vert_1 (appdata_t v)
  {
    return vertModulated(v, 1, 1);
  }

  v2f vert_2 (appdata_t v)
  {
    return vertModulated(v, 1.333, -1);
  }

  v2f vert_3 (appdata_t v)
  {
    return vertModulated(v, 1.77, -1);
  }

  // Input color is srgb
  fixed4 frag (v2f i) : SV_Target
  {
    // interior procedural line
    float procedural = ( abs(i.texcoord.y - 0.5) < .1 ) ? 2 : 0;
    i.color.a = 1; // kill any other alpha values that may come into this brush
    float4 c =  i.color + i.color * procedural;
    c = float4(c.rgb * c.a, 1.0);
    c = SrgbToNative(c);
    float preclamp;
    float completion = CalcFeather(i.clipinfo, c.a,preclamp);
    c*=completion;
    return c;
  }
ENDCG

Category {
  Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
  Blend One One //SrcAlpha One
  BlendOp Add, Min
  AlphaTest Greater .01
  ColorMask RGBA
  Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }


  SubShader {
    Pass {
      CGPROGRAM
      #pragma vertex vert_1
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      ENDCG
    }

    Pass {
      CGPROGRAM
      #pragma vertex vert_2
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      ENDCG
    }

    Pass {
      CGPROGRAM
      #pragma vertex vert_3
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      ENDCG
    }
  }
}
}
