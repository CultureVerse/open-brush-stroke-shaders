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

Shader "Brush/Special/DiffuseNoTextureDoubleSided_ModifiedWithTime" {
Properties {
  _Color ("Main Color", Color) = (1,1,1,1)
  _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

SubShader {
  Cull Off
  Tags{ "DisableBatching" = "True" }

  CGPROGRAM
  #pragma surface surf Lambert vertex:vert addshadow
  #pragma target 3.0
  #pragma multi_compile __ TBT_LINEAR_TARGET
  #include "../../../Shaders/Include/Brush.cginc"

  fixed4 _Color;

  struct appdata_t {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 texcoord0 : TEXCOORD0;
    float4 texcoord1 : TEXCOORD1;
    float4 texcoord2 : TEXCOORD2;
    
    UNITY_VERTEX_INPUT_INSTANCE_ID
  };


  struct Input {
    float2 uv_MainTex;
    float4 color : COLOR;
    fixed vface : VFACE;
    float clipinfo : TEXCOORD2;

    UNITY_VERTEX_OUTPUT_STEREO
  };

  void vert (inout appdata_t v, out Input o) {

    //
    // XXX - THIS TAPERING CODE SHOULD BE REMOVED ONCE THE TAPERING IS DONE IN THE GEOMETRY GENERATION
    // THE SHADER WILL REMAIN AS A SIMPLE "DiffuseNoTextureDoubleSided" SHADER.
    //

    UNITY_SETUP_INSTANCE_ID(v);
    UNITY_INITIALIZE_OUTPUT(Input, o);
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
    float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
    o.clipinfo = completon;

    float preclamp;
    completon = CalcFeather(o.clipinfo, 0, preclamp);
    preclamp = saturate(preclamp);

    float envelope = sin(v.texcoord0.x * 3.14159)*preclamp;
    float widthMultiplier = 1 - envelope; 
    v.vertex.xyz += -v.texcoord1 * widthMultiplier;
    v.color = TbVertToNative(v.color);
  }

  void surf (Input IN, inout SurfaceOutput o) {
    fixed4 c = _Color;
    o.Normal = float3(0,0,IN.vface);
    o.Albedo = c.rgb * IN.color.rgb;
  }
  ENDCG
}

Fallback "Transparent/Cutout/VertexLit"
}
