#region 引用

using System;
using UnityEngine;

#endregion

/// <summary>
/// 使用透明材料可以强制使用正向渲染模式，但不是需要的。
/// 所以为了在延迟渲染中添加雾，我们必须等到所有的灯都被渲染，然后再次传递雾。当雾覆盖整个场景时，就像渲染了一个方向灯。
/// </summary>
[ExecuteInEditMode]
public class DeferredFogEffect : MonoBehaviour
{
    public Shader DeferredFog;
    
    [NonSerialized]
    Material _fogMaterial; //Shader需要材质渲染，但是不需要asset，所以使用非序列化字段保存
    
    [NonSerialized]
    Camera _defferedCamera;
    [NonSerialized]
    Vector3[] _frustumCorners;
    [NonSerialized]
    Vector4[] _vectorArray; //我们不能直接使用 _frustumCorners。原因是我们只能向着色器传递4D 向量
    
    [ImageEffectOpaque]
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if(_fogMaterial == null)
        {
            _defferedCamera = GetComponent<Camera>();
            _frustumCorners = new Vector3[4];
            _vectorArray = new Vector4[4];
            _fogMaterial = new Material(DeferredFog);
        }
        //CalculateFrustumCorners 方法可以为我们做到这一点。它有四个参数。
        //第一个是要使用的矩形区域，在我们的例子中是整个图像。
        //第二个是投射射线的距离，它必须与远平面相匹配。
        //第三个参数涉及立体渲染。我们就用现在活跃的眼睛。
        //最后，该方法需要一个三维矢量数组来存储光线
        _defferedCamera.CalculateFrustumCorners(new Rect(0f,0f,1f,1f),_defferedCamera.farClipPlane,_defferedCamera.stereoActiveEye,_frustumCorners);
        
        //CalculateFrustumCorners 命令它们从左下角、从左上角、从右上角、从右下角。
        //然而，用于呈现图像效果的四边形有它的角顶点排列的左下角、右下角、左上角、右上角。那么让我们重新排列它们来匹配四边形的顶点。
        _vectorArray[0] = _frustumCorners[0];
        _vectorArray[1] = _frustumCorners[3];
        _vectorArray[2] = _frustumCorners[1];
        _vectorArray[3] = _frustumCorners[2];
        _fogMaterial.SetVectorArray("_FrustumCorners", _vectorArray);
        Graphics.Blit(src,dest,_fogMaterial);
    }
}