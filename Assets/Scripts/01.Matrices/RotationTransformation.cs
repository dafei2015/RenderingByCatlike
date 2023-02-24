using UnityEngine;

public class RotationTransformation : Transformation
{
    public Vector3 rotation;

    public override Matrix4x4 Matrix
    {
        get
        {
            var radX = rotation.x * Mathf.Deg2Rad;
            var radY = rotation.y * Mathf.Deg2Rad;
            var radZ = rotation.z * Mathf.Deg2Rad;
            var sinX = Mathf.Sin(radX);
            var cosX = Mathf.Cos(radX);
            var sinY = Mathf.Sin(radY);
            var cosY = Mathf.Cos(radY);
            var sinZ = Mathf.Sin(radZ);
            var cosZ = Mathf.Cos(radZ);

            var matrix = new Matrix4x4();
            matrix.SetColumn(0, new Vector4(
                cosY * cosZ,
                cosX * sinZ + sinX * sinY * cosZ,
                sinX * sinZ - cosX * sinY * cosZ,
                0f
            ));
            matrix.SetColumn(1, new Vector4(
                -cosY * sinZ,
                cosX * cosZ - sinX * sinY * sinZ,
                sinX * cosZ + cosX * sinY * sinZ,
                0f
            ));
            matrix.SetColumn(2, new Vector4(
                sinY,
                -sinX * cosY,
                cosX * cosY,
                0f
            ));
            matrix.SetColumn(3, new Vector4(0f, 0f, 0f, 1f));
            return matrix;
        }
    }
    // public override Vector3 Apply(Vector3 point)
    // {
    //     var radX = rotation.x * Mathf.Deg2Rad;
    //     var radY = rotation.y * Mathf.Deg2Rad;
    //     var radZ = rotation.z * Mathf.Deg2Rad;
    //     var sinX = Mathf.Sin(radX);
    //     var cosX = Mathf.Cos(radX);
    //     var sinY = Mathf.Sin(radY);
    //     var cosY = Mathf.Cos(radY);
    //     var sinZ = Mathf.Sin(radZ);
    //     var cosZ = Mathf.Cos(radZ);
    //
    //     var xAxis = new Vector3(
    //         cosY * cosZ,
    //         cosX * sinZ + sinX * sinY * cosZ,
    //         sinX * sinZ - cosX * sinY * cosZ
    //     );
    //     var yAxis = new Vector3(
    //         -cosY * sinZ,
    //         cosX * cosZ - sinX * sinY * sinZ,
    //         sinX * cosZ + cosX * sinY * sinZ
    //     );
    //     var zAxis = new Vector3(
    //         sinY,
    //         -sinX * cosY,
    //         cosX * cosY
    //     );
    //
    //     return xAxis * point.x + yAxis * point.y + zAxis * point.z;
    // }
}