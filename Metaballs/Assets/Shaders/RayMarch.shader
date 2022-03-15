Shader "Unlit/RayMarch"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #define MAX_STEPS 100
            #define MAX_DIST 100
            #define SURF_DIST .001

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 ro : TEXCOORD1;
                float3 hitPos : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                // local object space
                // o.ro = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos,1));
                // o.hitPos = v.vertex;

                // world
                o.ro = float4(_WorldSpaceCameraPos,1);
                o.hitPos = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }
            float maxcomp( in float2 v ) { return max( v.x,v.y); }

            float GetDist(float3 p){
                // cube
                float3 d = abs(p) - .2;
                float3 b = min(max(d.x,max(d.y,d.z)),0.0) + length(max(d,0.0));
                
                // sphere
                float3 s = float3(0,sin(-.1*_Time.x*100)+.05,0);
                float k = .5;
                float a = length(p - s.xyz) - .2;

                // polynomial smooth min
                float h = max( k-abs(a-b), 0.0 )/k;
                return min( a, b ) - h*h*h*k*(1.0/6.0);

               
            }

            float RayMarch(float3 ro, float3 rd){
                float dO = 0;
                float dS;
                for(int i = 0; i< MAX_STEPS; i++){
                    float3 p = ro + dO * rd;
                    dS = GetDist(p);
                    dO += dS;
                    if(dS < SURF_DIST || dO > MAX_DIST) break;
                }

                return dO;

            }

            float3 GetNormal(float3 p){
                float2 e = float2(.001,0);
                float3 n = GetDist(p) - float3(
                    GetDist(p-e.xyy),
                    GetDist(p-e.yxy),
                    GetDist(p-e.yyx)
                );
                return normalize(n);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float2 uv = i.uv -.5;
                // camera
                float3 ro = i.ro;
                float3 rd = normalize(i.hitPos - ro);
                
                float d = RayMarch(ro,rd);
                fixed4 col = float4(0,0,0,0);

                if(d<MAX_DIST){
                    float3 p = ro + rd *d;
                    float3 n = GetNormal(p);

                    col.rgb = n;
                }else{
                    // discards background fragments
                    discard;
                }
                return col;
            }
            ENDCG
        }
    }
}
