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

Shader "Brush/Special/VelvetInk_ModifiedWithTime" {
Properties {
  _MainTex ("Texture", 2D) = "white" {}
  _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1
   _AlbedoFadeEdgeLength("Albedo Fade Edge Width", Float) = 0.05

}

Category {
  Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
  Blend SrcAlpha One
  AlphaTest Greater .01
  ColorMask RGB
  Cull Off Lighting Off ZWrite Off Fog { Color (0,0,0,0) }

  SubShader {
    Pass {

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma multi_compile __ AUDIO_REACTIVE
      #pragma multi_compile __ TBT_LINEAR_TARGET
      #include "UnityCG.cginc"
      #include "../../../Shaders/Include/Brush.cginc"

      sampler2D _MainTex;

      struct appdata_t {
        float4 vertex : POSITION;
        fixed4 color : COLOR;
        float3 normal : NORMAL;
        float2 texcoord : TEXCOORD0;
        float4 texcoord2 : TEXCOORD2;
        UNITY_VERTEX_INPUT_INSTANCE_ID

      };

      struct v2f {
        float4 vertex : SV_POSITION;
        fixed4 color : COLOR;
        float2 texcoord : TEXCOORD0;
        float clipinfo : TEXCOORD1;
        UNITY_VERTEX_OUTPUT_STEREO
      };

      float4 _MainTex_ST;
        float _Cutoff;
        uniform float _AlbedoFadeEdgeLength;
        uniform float _AlbedoFadeEdgePower;

      v2f vert (appdata_t v)
      {
        v2f o;
                        UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

        float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
        o.clipinfo = completon;

        o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
#ifdef AUDIO_REACTIVE
        v.color = TbVertToSrgb(v.color);
        o.color = musicReactiveColor(v.color, _BeatOutput.w);
        v.vertex = musicReactiveAnimation(v.vertex, v.color, _BeatOutput.w, o.texcoord.x);
        o.color = SrgbToNative(o.color);
#else
        o.color = TbVertToNative(v.color);
#endif
        o.vertex = UnityObjectToClipPos(v.vertex);

        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {

        half4 c = tex2D(_MainTex, i.texcoord );
        float preclamp;
        float completion = CalcFeather(i.clipinfo, c.a, preclamp);
        preclamp = (saturate(_AlbedoFadeEdgeLength - preclamp)/_AlbedoFadeEdgeLength);
        preclamp = 1-preclamp;
        c*=preclamp;


        return i.color * c;
      }
      ENDCG
    }
  }
}
}
