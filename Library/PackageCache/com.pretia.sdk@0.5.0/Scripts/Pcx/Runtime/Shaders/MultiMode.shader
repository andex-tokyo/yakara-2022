Shader "Hidden/PCX/Multi Mode"
{
    Properties
    {
        [HDR] _Color("Tint", Color) = (1, 1, 1, 1)
        _PointSize("Point Size", Float) = 0.05
    }

    CGINCLUDE

    #include "Common.cginc"

    struct Attributes
    {
        float4 position : POSITION;
        half4 color : COLOR;
    };

    struct Varyings
    {
        float4 position : SV_POSITION;
        half3 color : COLOR;
        half psize : PSIZE;
        UNITY_FOG_COORDS(1)
    };

    half4 _Tint;
    float4x4 _Transform;
    half _PointSize;

    StructuredBuffer<float4> _PointBuffer;

    half4 Fragment(Varyings input) : SV_Target
    {
        half4 c = half4(input.color, _Tint.a);
        UNITY_APPLY_FOG(input.fogCoord, c);
        return c;
    }

    float4 Disc(float4 pt, uint vid, uint div)
    {
        float4 pos = mul(_Transform, float4(pt.xyz, 1));
        float4 origin = UnityObjectToClipPos(pos);
        float2 extent = abs(UNITY_MATRIX_P._11_22 * _PointSize);

        // Determine the number of slices based on the radius of the
        // point on the screen.
        float radius = extent.y / origin.w * _ScreenParams.y;
        uint slices = min((radius + 1) / 5, 4) + 2;

        uint i = vid % 3;
        uint fin = vid / 3;

        if (i == 0)
        {
            return origin;
        }
        else
        {
            float cs, sn;
            sincos(UNITY_PI * 2 * (fin + i - 1) / div, sn, cs);
            return origin + float4(extent * float2(sn, cs), 0, 0);
        }
    }

    ENDCG

    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Cull Off

        Pass
        {
            CGPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog

            Varyings Vertex(uint vid : SV_VertexID)
            {
                float4 pt = _PointBuffer[vid];
                float4 pos = mul(_Transform, float4(pt.xyz, 1));
                half3 col = PcxDecodeColor(asuint(pt.w));

                #if !PCX_SHADOW_CASTER
                    // Color space convertion & applying tint
                    #if UNITY_COLORSPACE_GAMMA
                        col *= _Tint.rgb * 2;
                    #else
                        col *= LinearToGammaSpace(_Tint.rgb) * 2;
                        col = GammaToLinearSpace(col);
                    #endif
                #endif

                Varyings o;
                o.position = UnityObjectToClipPos(pos);
                o.color = col;
                o.psize = _PointSize / o.position.w * _ScreenParams.y;
                
                UNITY_TRANSFER_FOG(o, o.position);
                return o;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog

            Varyings Vertex(uint vid : SV_VertexID, uint iid : SV_InstanceID)
            {
                float4 pt = _PointBuffer[iid];

                Varyings o;
                o.position = Disc(pt, vid, 4);
                o.color = PcxDecodeColor(asuint(pt.w));

                #if !PCX_SHADOW_CASTER
                    // Color space convertion & applying tint
                    #if UNITY_COLORSPACE_GAMMA
                        o.color *= _Tint.rgb * 2;
                    #else
                        o.color *= LinearToGammaSpace(_Tint.rgb) * 2;
                        o.color = GammaToLinearSpace(col);
                    #endif
                #endif

                UNITY_TRANSFER_FOG(o, o.position);
                return o;
            }

            ENDCG
        }

        Pass
        {
            CGPROGRAM

            #pragma vertex Vertex
            #pragma fragment Fragment
            #pragma multi_compile_fog

            Varyings Vertex(uint vid : SV_VertexID, uint iid : SV_InstanceID)
            {
                float4 pt = _PointBuffer[iid];

                Varyings o;
                o.position = Disc(pt, vid, 12);
                o.color = PcxDecodeColor(asuint(pt.w));

                #if !PCX_SHADOW_CASTER
                    // Color space convertion & applying tint
                    #if UNITY_COLORSPACE_GAMMA
                        o.color *= _Tint.rgb * 2;
                    #else
                        o.color *= LinearToGammaSpace(_Tint.rgb) * 2;
                        o.color = GammaToLinearSpace(col);
                    #endif
                #endif

                UNITY_TRANSFER_FOG(o, o.position);
                return o;
            }

            ENDCG
        }
    }
}
