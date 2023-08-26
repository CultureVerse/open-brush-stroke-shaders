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

Shader "Brush/DiffuseOpaqueDoubleSided_ModifiedWithTime" {
Properties {
  _Color ("Main Color", Color) = (1,1,1,1)
  _Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
    _ClipStart ("Clip Start", Float) = 0
    _ClipEnd ("Clip End", Float) = 1
    _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

SubShader {

Cull Off

CGPROGRAM
#pragma surface surf Lambert vertex:vert addshadow alphatest:_Cutoff
#pragma multi_compile __ TBT_LINEAR_TARGET
#pragma target 3.0
#include "../../../Shaders/Include/Brush.cginc"

fixed4 _Color;

struct Input {
  float4 color : COLOR;
  float4 normal : NORMAL;
  fixed vface : VFACE;
  float clipinfo;
};

void vert(inout appdata_full v, out Input o) {
  v.color = TbVertToNative(v.color);
    UNITY_INITIALIZE_OUTPUT(Input, o);
  v.texcoord2.w = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
  o.clipinfo = v.texcoord2.w;

}

void surf (Input IN, inout SurfaceOutput o) {
  o.Albedo = _Color * IN.color.rgb;
  o.Normal = float3(0,0,IN.vface);
  float completion = CalcFeather(IN.clipinfo, cos( (IN.normal.x*0.5+0.5 )*7 )+ (IN.normal.z*0.5+0.5)*0.5);
  o.Alpha = _Color.a* IN.color.a* completion;

}
ENDCG
}

Fallback "Diffuse"
}
