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

Shader "Brush/Special/Toon_ModifiedWithTime" {
Properties {
  _MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
  _OutlineMax("Maximum outline size", Range(0, .5)) = .005
  _ClipStart ("Clip Start", Float) = 0
  _ClipEnd ("Clip End", Float) = 1
  _BrushFeatherSig("Brush Feather Sig", Float) =0.1

}

CGINCLUDE
  #include "UnityCG.cginc"
  #include "../../../Shaders/Include/Brush.cginc"
  #include "Assets/ThirdParty/Noise/Shaders/Noise.cginc"
  #pragma multi_compile __ AUDIO_REACTIVE
  #pragma multi_compile __ TBT_LINEAR_TARGET
  #pragma multi_compile_fog
  #pragma target 3.0
  sampler2D _MainTex;
  float4 _MainTex_ST;
  float _OutlineMax;

  struct appdata_t {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float3 normal : NORMAL;
    float3 texcoord : TEXCOORD0;
    float4 texcoord2 : TEXCOORD2;
UNITY_VERTEX_INPUT_INSTANCE_ID
  };

  struct v2f {
    float4 vertex : SV_POSITION;
    fixed4 color : COLOR;
    float2 texcoord : TEXCOORD0;
    float clipinfo : TEXCOORD1;
UNITY_VERTEX_OUTPUT_STEREO
    UNITY_FOG_COORDS(2)
  };

  v2f vertInflate (appdata_t v, float inflate)
  {

    v2f o;
    UNITY_SETUP_INSTANCE_ID(v); //Insert
    UNITY_INITIALIZE_OUTPUT(v2f, o); //Insert
    UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o); //Insert

    float outlineEnabled = inflate;
    float radius = v.texcoord.z;
    inflate *= radius * .4;
    float bulge = 0.0;
	  float3 worldNormal = UnityObjectToWorldNormal(v.normal);
    float completon = invLerp(v.texcoord2.x, v.texcoord2.y, v.texcoord2.z);
    o.clipinfo = completon;

#ifdef AUDIO_REACTIVE
    float fft = tex2Dlod(_FFTTex, float4(_BeatOutputAccum.z*.25 + v.texcoord.x, 0,0,0)).g;
    bulge = fft * radius * 10.0;
#endif

    //
    // Careful: perspective projection is non-afine, so math assumptions may not be valid here.
    //

    // Technically these are not yet in NDC because they haven't been divided by W, so their
    // range is currently [-W, W].
    o.vertex = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal.xyz * bulge, v.vertex.w));
    float4 outline_NDC = UnityObjectToClipPos(float4(v.vertex.xyz + v.normal.xyz * inflate, v.vertex.w));

    // Displacement in proper NDC coords (e.g. [-1, 1])
    float3 disp = outline_NDC.xyz / outline_NDC.w - o.vertex.xyz / o.vertex.w;

    // Magnitude is a scaling factor to shrink large outlines down to a max width, in NDC space.
    // Notice here we're only measuring 2D displacment in X and Y.
    float mag = length(disp.xy);
    mag = min(_OutlineMax, mag) / mag;

    // Ideally we would project back into world space to do the scaling, but the inverse
    // projection matrix is not currently available. So instead, we multiply back in the w
    // component so both sides of the += operator below are in the same space. Also note
    // that the w component is a function of depth, so modifying X and Y independent of Z
    // should mean that the original w value remains valid.
    o.vertex.xyz += float3(disp.xy * mag, disp.z) * o.vertex.w * outlineEnabled;

    // Push Z back to avoid z-fighting when scaled very small. This is not legit,
    // mathematically speaking and likely causes crazy surface derivitives.
    o.vertex.z -= disp.z * o.vertex.w * outlineEnabled;

        o.color = v.color;
        o.color.a = 1;
        o.color.xyz += worldNormal.y *.2;
        o.color.xyz = max(0, o.color.xyz);
        o.texcoord = TRANSFORM_TEX(v.texcoord,_MainTex);
    UNITY_TRANSFER_FOG(o, o.vertex);
        return o;
  }

  v2f vert (appdata_t v)
  {
    v.color = TbVertToNative(v.color);
    return vertInflate(v,0);
  }

  v2f vertEdge (appdata_t v)
  {
    // v.color = TbVertToNative(v.color); no need
    return vertInflate(v, 1.0);
  }

  fixed4 fragBlack (v2f i) : SV_Target
  {
    float4 color = float4(0,0,0,1);
    UNITY_APPLY_FOG(i.fogCoord, color);
    float preclamp;
    float completion = CalcFeather(i.clipinfo,  0,preclamp);
    preclamp= saturate(preclamp*40.0);
    color*=preclamp;
    if(color.a <=0)
      discard;

    return color;
  }

  fixed4 fragColor (v2f i) : SV_Target
  {
    UNITY_APPLY_FOG(i.fogCoord, i.color);

    float preclamp;
    float completion = CalcFeather(i.clipinfo,  0,preclamp);
    preclamp= saturate(preclamp*500.0);
    i.color.a*=preclamp;
    i.color.rgb *= (preclamp);
    if(i.color.a <=0)
      discard;
    return i.color;
  }

ENDCG



SubShader {
  // For exportManifest.json:
  //   GltfCull Back
  Cull Back
  Pass{

    CGPROGRAM
    #pragma vertex vert
    #pragma fragment fragColor
    ENDCG
    }

  Cull Front
  Pass{

    CGPROGRAM
    #pragma vertex vertEdge
    #pragma fragment fragBlack
    ENDCG
    }
  }
Fallback "Diffuse"
}
