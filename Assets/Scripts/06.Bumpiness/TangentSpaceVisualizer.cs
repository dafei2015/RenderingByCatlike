using UnityEngine;

public class TangentSpaceVisualizer : MonoBehaviour
{
    public float offset = 0.01f;
    public float scale = 0.1f;
    public void OnDrawGizmos()
    {
       
        var filter = GetComponent<MeshFilter>();
        if (filter)
        {
            var mesh = filter.sharedMesh;
            if (mesh) ShowTangentSpace(mesh);
        }
    }

    private void ShowTangentSpace(Mesh mesh)
    {
        var vertices = mesh.vertices; //顶点位置,本地坐标，需要转换为世界坐标;
        var normals = mesh.normals; //法线位置,本地坐标，需要转换为世界坐标;
        var tangents = mesh.tangents; //法线位置,本地坐标，需要转换为世界坐标;

        for (var i = 0; i < vertices.Length; i++) ShowTangentSpace(transform.TransformPoint(vertices[i]), 
            transform.TransformDirection(normals[i]),transform.TransformDirection(tangents[i]),tangents[i].w);
    }

    private void ShowTangentSpace(Vector3 vertex, Vector3 normal,Vector3 tangent,float binormalSign)
    {
        vertex += normal *offset;
        Gizmos.color = Color.green;
        Gizmos.DrawLine(vertex, vertex + normal*scale);
        Gizmos.color = Color.red;
        Gizmos.DrawLine(vertex, vertex + tangent*scale);
        
        Vector3 binormal = Vector3.Cross(normal,tangent)*binormalSign;
        Gizmos.color = Color.blue;
        Gizmos.DrawLine(vertex, vertex + binormal * scale);
    }
}