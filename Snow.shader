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

Shader "Brush/Particle/Snow_ModifiedWithTime" {
Properties {
  _TintColor ("Tint Color", Color) = (0.5,0.5,0.5,0.5)
  _MainTex ("Particle Texture", 2D) = "white" {}
  _ScrollRate("Scroll Rate", Float) = 1.0
  _ScrollDistance("Scroll Distance", Vector) = (1.0, 0, 0)
  _ScrollJitterIntensity("Scroll Jitter Intensity", Float) = 1.0
  _ScrollJitterFrequency("Scroll Jitter Frequency", Float) = 1.0
  _SpreadRate ("Spread Rate", Range(0.3, 5)) = 1.539
      _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

Category {
  Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True" }
  Blend SrcAlpha One
  AlphaTest Greater .01
  ColorMask RGB
  Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

  SubShader {
    Pass {

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile_particles
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      #pragma target 3.0

      #include "UnityCG.cginc"
      #include "../../../Shaders/Include/Brush.cginc"
      #include "../../../Shaders/Include/Particles.cginc"

      sampler2D _MainTex;
      fixed4 _TintColor;

      struct v2f {
        float4 vertex : SV_POSITION;
        fixed4 color : COLOR;
        float2 texcoord : TEXCOORD0;
        float clipinfo : TEXCOORD2;
UNITY_VERTEX_OUTPUT_STEREO
      };

      float4 _MainTex_ST;
      float _ScrollRate;
      float3 _ScrollDistance;
      float _ScrollJitterIntensity;
      float _ScrollJitterFrequency;
      float _SpreadRate;

      v2f vert (ParticleVertexWithSpread_t v)
      {
        v2f o;
                UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert
        
        v.color = TbVertToSrgb(v.color);
        float birthTime = v.texcoord.w;
        float rotation = v.texcoord.z;
        float halfSize = GetParticleHalfSize(v.corner.xyz, v.center, birthTime);
        float spreadProgress = SpreadProgress(birthTime, _SpreadRate);
        float4 center = SpreadParticle(v, spreadProgress);
        float4 center_WS = mul(unity_ObjectToWorld, center);

        // Custom vertex animation
        float scrollAmount = _Time.y;
        float t = fmod(scrollAmount * _ScrollRate + v.color.a, 1);
        float4 dispVec = (t - .5f) * float4(_ScrollDistance, 0.0);
        dispVec.x += sin(t * _ScrollJitterFrequency + _Time.y) * _ScrollJitterIntensity;
        dispVec.z += cos(t * _ScrollJitterFrequency * .5 + _Time.y) * _ScrollJitterIntensity;
        dispVec.xyz = spreadProgress * dispVec * kDecimetersToWorldUnits;
        center_WS += mul(xf_CS, dispVec);

        float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
        o.clipinfo = completon;

        float4 corner_WS = OrientParticle_WS(center_WS.xyz, halfSize, v.vid, rotation);
#ifdef AUDIO_REACTIVE
        o.color = musicReactiveColor(v.color, _BeatOutput.w);
        corner_WS = musicReactiveAnimationWorldSpace(corner_WS, v.color, _BeatOutput.w, corner_WS.y*5);
#else
        o.color = v.color;
#endif

        o.vertex = mul(UNITY_MATRIX_VP, corner_WS);
        o.color.a = pow(1 - abs(2*(t - .5)), 3);
        o.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
        return o;
      }

      // Input color is srgb
      fixed4 frag (v2f i) : SV_Target
      {
        float4 tex = tex2D(_MainTex, i.texcoord);
         float preclamp;
          float completion = CalcFeather(i.clipinfo, tex.a,preclamp);
          preclamp= saturate(preclamp*1.5);

        return SrgbToNative(2.0f * i.color * _TintColor * tex*preclamp);
      }
      ENDCG
    }
  }
}
}
