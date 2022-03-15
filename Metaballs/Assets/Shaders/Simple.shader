Shader "Unlit/NewUnlitShader"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            static const int MAX_STEPS = 100;
            static const float MAX_DIST = 100;
            static const float SURF_DIST = .01;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }
            float GetDist(float3 p){
                float4 s = float4(2,1,6,1);
                float4 s2 = float4(.5,1,6,1);
                
                float sphereDist = length(p-s.xyz) - s.w;
                float sphereDist2 = length(p-s2.xyz) - s2.w;

                float planeDist = p.y;

                float d = min(sphereDist,planeDist);
                d = min(d,sphereDist2);
                return d;
            }
            float RayMarch (float3 ro, float3 rd){
                float dO = 0;
                for(int i=0; i < MAX_STEPS; i++){
                    float3 p = ro + mul(rd,dO);
                    float dS = GetDist(p);
                    dO += dS;
                    if(dO > MAX_DIST || dS < SURF_DIST) break;
                }
                return dO;
            }
            float3 GetNormal(float3 p) {
                float d = GetDist(p);
                float2 e = float2(.0001, 0);
                
                float3 n = d - float3(
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx));
                
                return normalize(n);
            }
            float GetLight(float3 p) {
                float3 lightPos = float3(1, 5, 3);
                lightPos.xz += float2(mul(sin(_Time.y), cos(_Time.y)),2.);
                float3 l = normalize(lightPos-p);
                float3 n = GetNormal(p);
                
                float dif = clamp(dot(n, l), 0, 1);
                float d = RayMarch(p+n*SURF_DIST*2., l);
                if(d<length(lightPos-p)) dif = mul(dif, .1);
                
                return dif;
            }


            float4 frag (v2f i) : SV_Target
            {
                //float2 uv = (i.uv -.5*_ScreenParams.xy)/_ScreenParams.y;
                float2 uv = i.uv -.3f;
                float3 col = float3(1,1,1);

                float3 ro = float3(0,1,0);
                float3 rd = normalize(float3(uv.x,uv.y,1));
                
                float d = RayMarch(ro,rd);
                float3 p = ro + mul(rd,d);
                float dif = GetLight(p);
                col = float3(dif,dif,dif);
                float gammaCorrection = 2;
                col = pow(col, float3(gammaCorrection,gammaCorrection,gammaCorrection));

                return float4(col,1.);
            }
            ENDCG
        }
    }
}
