#if !defined(TESSELLATION22_INCLUDED)
#define TESSELLATION22_INCLUDED

float _TessellationUniform;
float _TessellationEdgeLength;

struct TessellationFactors
{
    float edge[3]:SV_TessFactor;
    float inside:SV_InsideTessFactor;
};


struct TessellationControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float3 normal : NORMAL;
    float4 tangent : TANGENT;
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};
float TessellationEdgeFactor (float3 p0, float3 p1)
{
    #if defined(_TESSELLATION_EDGE)
        //以世界坐标长度计算
        // float3 p0 = mul(unity_ObjectToWorld, float4(cp0.vertex.xyz, 1)).xyz;
        // float3 p1 = mul(unity_ObjectToWorld, float4(cp1.vertex.xyz, 1)).xyz;
        // float edgeLength = distance(p0, p1);
        // return edgeLength / _TessellationEdgeLength;

        //以屏幕像素计算
        // float4 p0 = UnityObjectToClipPos(cp0.vertex);
        // float4 p1 = UnityObjectToClipPos(cp1.vertex);
        // float edgeLength = distance(p0.xy / p0.w, p1.xy / p1.w);
        // return edgeLength * _ScreenParams.y / _TessellationEdgeLength;

        //以世界坐标长度和视距计算
        // float3 p0 = mul(unity_ObjectToWorld, float4(cp0.vertex.xyz, 1)).xyz;
        // float3 p1 = mul(unity_ObjectToWorld, float4(cp1.vertex.xyz, 1)).xyz;
        float edgeLength = distance(p0, p1);
    
        float3 edgeCenter = (p0 + p1) * 0.5;
        float viewDistance = distance(edgeCenter, _WorldSpaceCameraPos);
    
    return edgeLength * _ScreenParams.y /(_TessellationEdgeLength * viewDistance);
    #else
        return _TessellationUniform;
    #endif
}
TessellationControlPoint  MyTessellationVertexProgram(VertexData v)
{
    TessellationControlPoint p;
    p.vertex = v.vertex;
    p.normal = v.normal;
    p.tangent = v.tangent;
    p.uv = v.uv;
    p.uv1 = v.uv1;
    p.uv2 = v.uv2;
    return p;
}

[UNITY_domain("tri")]  //首先，我们必须明确地告诉它它正在处理三角形。这是通过 UNITY _ domain 属性完成的，使用 tri 作为参数。
[UNITY_outputcontrolpoints(3)] //每个补丁输出三个控制点，三角形的每个角都有一个控制点。
[UNITY_outputtopology("triangle_cw")] //告诉图形处理器三角形的方向，Unity是顺时针
[UNITY_partitioning("fractional_even")]  //GPU还需要知道如何切断碎片，目前使用整数模式,fractional_odd基于浮点数的奇数模式，fractional_even偶数模式
[UNITY_patchconstantfunc("MyPatchConstantFunction")] //GPU 还必须知道到多少部分的碎片应该削减。每个碎片可以有所不同。我们必须提供一个函数来计算这个函数，
                                                    //称为补丁常数函数。假设我们有这样一个函数，名为 MyPatchConstantfunction。
TessellationControlPoint  MyHullProgram(InputPatch<TessellationControlPoint ,3> patch,uint id:SV_OutputControlPointID)
{
    return patch[id];
}

TessellationFactors MyPatchConstantFunction(InputPatch<TessellationControlPoint ,3> patch)
{
    
    // TessellationFactors f;
    // f.edge[0] = TessellationEdgeFactor(patch[1], patch[2]);
    // f.edge[1] = TessellationEdgeFactor(patch[2], patch[0]);
    // f.edge[2] = TessellationEdgeFactor(patch[0], patch[1]);
    // f.inside = (TessellationEdgeFactor(patch[1], patch[2]) +
    //             TessellationEdgeFactor(patch[2], patch[0]) +
    //             TessellationEdgeFactor(patch[0], patch[1])) * (1 / 3.0);
    float3 p0 = mul(unity_ObjectToWorld, patch[0].vertex).xyz;
    float3 p1 = mul(unity_ObjectToWorld, patch[1].vertex).xyz;
    float3 p2 = mul(unity_ObjectToWorld, patch[2].vertex).xyz;
    TessellationFactors f;
    f.edge[0] = TessellationEdgeFactor(p1, p2);
    f.edge[1] = TessellationEdgeFactor(p2, p0);
    f.edge[2] = TessellationEdgeFactor(p0, p1);
    f.inside = (TessellationEdgeFactor(p1, p2) +
                TessellationEdgeFactor(p2, p0) +
                TessellationEdgeFactor(p0, p1)) * (1 / 3.0);
    return f;
}

[UNITY_domain("tri")]
InterpolatorsVertex  MyDomainProgram(TessellationFactors factors,OutputPatch<TessellationControlPoint ,3> patch,float3 barycentricCoordinates:SV_DomainLocation)
{
    VertexData data;
    #define MY_DOMAIN_PROGRAM_INTERPOLATE(fieldName) data.fieldName = \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z;
    MY_DOMAIN_PROGRAM_INTERPOLATE(vertex);
    MY_DOMAIN_PROGRAM_INTERPOLATE(normal)
    MY_DOMAIN_PROGRAM_INTERPOLATE(tangent)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv1)
    MY_DOMAIN_PROGRAM_INTERPOLATE(uv2)

    return MyVertexProgram(data);
}
#endif