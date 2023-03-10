#if !defined(FLAT_WIREFRAME_INCLUDED)
#define FLAT_WIREFRAME_INCLUDED

#define CUSTOM_GEOMETRY_INTERPOLATORS float2 barycentricCoordinates : TEXCOORD9;

#include "My Lighting Input21.cginc"

float3 _WireframeColor;
float _WireframeSmoothing;
float _WireframeThickness;

float3 GetAlbedoWithWireframe( Interpolators i)
{
    float3 albedo = GetAlbedo(i);
    float3 barys;
    barys.xy = i.barycentricCoordinates;
    barys.z = 1-barys.x-barys.y;
    float3 deltas = fwidth(barys);
    float3 smoothing = deltas * _WireframeSmoothing;
    float3 thickness = deltas * _WireframeThickness;
    barys = smoothstep(thickness, thickness + smoothing, barys);
    float minBary = min(barys.x, min(barys.y, barys.z));
    return lerp(_WireframeColor, albedo, minBary);
}
#define ALBEDO_FUNCTION GetAlbedoWithWireframe

#include "My Lighting21.cginc"

struct InterpolatorsGeometry
{
    InterpolatorsVertex data;
    CUSTOM_GEOMETRY_INTERPOLATORS
};

//几何着色器 只有在target4.0 以上才支持，位于vertex和fragment之间
// 它被提供顶点程序的输出，按每个基元分组。一个几何程序可以修改这些数据，在它被插值并用于渲染片段之前。
[maxvertexcount(3)]
void MyGeometryProgram (triangle InterpolatorsVertex i[3],inout TriangleStream<InterpolatorsGeometry> stream)
{
    float3 p0 = i[0].worldPos.xyz;
    float3 p1 = i[1].worldPos.xyz;
    float3 p2 = i[2].worldPos.xyz;
    
    float3 triangleNormal = normalize(cross(p1-p0,p2-p0));
    i[0].normal = triangleNormal;
    i[1].normal = triangleNormal;
    i[2].normal = triangleNormal;

    InterpolatorsGeometry g0,g1,g2;
    g0.data = i[0];
    g1.data = i[1];
    g2.data = i[2];

    g0.barycentricCoordinates = float2(1, 0);
    g1.barycentricCoordinates = float2(0, 1);
    g2.barycentricCoordinates = float2(0, 0);
    
    stream.Append(g0);
    stream.Append(g1);
    stream.Append(g2);   
}

#endif