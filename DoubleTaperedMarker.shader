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

Shader "Brush/Special/DoubleTaperedMarker_ModifiedWithTime" {
Properties {
    _ExpansionFactor("Expander", Float) = 1
    _ClipStart ("Clip Start", Float) = 0
    _ClipEnd ("Clip End", Float) = 1
    _BrushFeatherSig("Brush Feather Sig", Float) =0.1

    }

Category {
  Cull Off Lighting Off

  SubShader {
    Tags{ "DisableBatching" = "True" }
    Pass {

      CGPROGRAM
      #pragma vertex vert
      #pragma fragment frag
      #pragma target 3.0
      #pragma multi_compile_particles
      #pragma multi_compile_fog
      #pragma multi_compile __ TBT_LINEAR_TARGET

      #include "UnityCG.cginc"
      #include "../../../Shaders/Include/Brush.cginc"

      sampler2D _MainTex;
      float _ExpansionFactor;
      struct appdata_t {
        float4 vertex : POSITION;
        fixed4 color : COLOR;
        float2 texcoord0 : TEXCOORD0;
        float3 texcoord1 : TEXCOORD1; //per vert offset vector
        float4 texcoord2 : TEXCOORD2;
        UNITY_VERTEX_INPUT_INSTANCE_ID
      };

      struct v2f {
        float4 vertex : SV_POSITION;
        fixed4 color : COLOR;
        float2 texcoord : TEXCOORD0;
        float clipinfo : TEXCOORD1;

        UNITY_FOG_COORDS(2)
UNITY_VERTEX_OUTPUT_STEREO
      };

      v2f vert (appdata_t v)
      {

        //
        // XXX - THIS SHADER SHOULD BE DELETED AFTER WE TAPERING IS DONE IN THE GEOMETRY GENERATION
        //

        v2f o;
                        UNITY_SETUP_INSTANCE_ID(v); //Insert
                UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

        float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
        o.clipinfo = completon;
        float preclamp;
        completon = CalcFeather(o.clipinfo, 0, preclamp);
        preclamp = saturate(preclamp*_ExpansionFactor);
        
        float envelope = sin(v.texcoord0.x * 3.14159)*preclamp;
        float widthMultiplier = 1 - envelope;
        v.vertex.xyz += -v.texcoord1 * widthMultiplier;
        o.vertex = UnityObjectToClipPos(v.vertex);
        o.color = v.color;//TbVertToNative(v.color);
        o.texcoord = v.texcoord0;
        UNITY_TRANSFER_FOG(o, o.vertex);
        return o;
      }

      fixed4 frag (v2f i) : SV_Target
      {

        UNITY_APPLY_FOG(i.fogCoord, i.color.rgb);
        return float4(i.color.rgb, 1);

      }

      ENDCG
    }
  }
}
}
