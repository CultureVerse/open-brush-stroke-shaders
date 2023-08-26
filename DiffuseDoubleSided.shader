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

Shader "Brush/DiffuseDoubleSided_ModifiedWithTime" {
Properties {
  _Color ("Main Color", Color) = (1,1,1,1)
  _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
  _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
      _ClipStart ("Clip Start", Float) = 0
    _ClipEnd ("Clip End", Float) = 1
    _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

SubShader {
  Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
  LOD 200
  Cull Off

CGPROGRAM
#pragma surface surf Lambert vertex:vert alphatest:_Cutoff addshadow
#pragma multi_compile __ TBT_LINEAR_TARGET
#include "../../../Shaders/Include/Brush.cginc"
#pragma target 3.0

sampler2D _MainTex;
fixed4 _Color;

struct Input {
  float2 uv_MainTex;
  float4 color : COLOR;
  fixed vface : VFACE;
    float clipinfo;

};

void vert (inout appdata_full v, out Input o) {
  v.color = TbVertToNative(v.color);
  UNITY_INITIALIZE_OUTPUT(Input, o);
  v.texcoord2.w = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
  o.clipinfo = v.texcoord2.w;

}

void surf (Input IN, inout SurfaceOutput o) {
  fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
  o.Albedo = c.rgb * IN.color.rgb;
  float completion = CalcFeather(IN.clipinfo, c.a);
  o.Alpha = c.a * IN.color.a* completion;
  o.Normal = float3(0,0,IN.vface);
}
ENDCG
}


// MOBILE VERSION
SubShader {
  Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
  LOD 100
  Cull Off

CGPROGRAM
#pragma surface surf Lambert vertex:vert alphatest:_Cutoff
#pragma multi_compile __ TBT_LINEAR_TARGET
#include "../../../Shaders/Include/Brush.cginc"
#pragma target 3.0

sampler2D _MainTex;
fixed4 _Color;

struct Input {
  float2 uv_MainTex;
  float4 color : COLOR;
  fixed vface : VFACE;
};

void vert (inout appdata_full v) {
  v.color = TbVertToNative(v.color);
}

void surf (Input IN, inout SurfaceOutput o) {
  fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
  o.Albedo = c.rgb * IN.color.rgb;
  o.Alpha = c.a * IN.color.a;
  o.Normal = float3(0,0,IN.vface);
}
ENDCG
}

Fallback "Transparent/Cutout/VertexLit"
}
