#region 引用

using System;
using UnityEngine;

#endregion

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class DepthOfFieldEffect : MonoBehaviour
{
    [Range(0.1f,100f)]
    public float FocusDistance = 10f;
    [Range(0.1f,10f)]
    public float FocusRange =3f;
    [Range(1f,10f)]
    public float BokehRadius =4f;
    [HideInInspector] public Shader DofShader;
    [NonSerialized] Material _dof;

    const int CircleOfConfusionPass =0;
    const int PreFiltePass =1;
    const int BokehPass =2;
    const int PostFilterPass =3;
    const int CombinePass =4;
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_dof == null)
        {
            _dof = new Material(DofShader);
            _dof.hideFlags = HideFlags.HideAndDontSave;
        }
        
        _dof.SetFloat("_BokehRadius",BokehRadius);
        _dof.SetFloat("_FocusDistance",FocusDistance);
        _dof.SetFloat("_FocusRange",FocusRange);
        
        RenderTexture coc = RenderTexture.GetTemporary(src.width,src.height,0,RenderTextureFormat.RHalf,RenderTextureReadWrite.Linear);

        int width = src.width/2;
        int height = src.height/2;
        RenderTextureFormat format = src.format;
        RenderTexture dof0 = RenderTexture.GetTemporary(width,height,0,format);
        RenderTexture dof1 = RenderTexture.GetTemporary(width,height,0,format);
        
        _dof.SetTexture("_CoCTex",coc);
        _dof.SetTexture("_DoFTex",dof0);
        //Blit 只是对相邻的纹理取平均值，这对于深度值或从深度值派生出来的东西没有意义
        Graphics.Blit(src,coc,_dof,CircleOfConfusionPass);
        Graphics.Blit(src,dof0,_dof,PreFiltePass);
        Graphics.Blit(dof0,dof1,_dof,BokehPass);
        Graphics.Blit(dof1,dof0,_dof,PostFilterPass);
        Graphics.Blit(src, dest,_dof,CombinePass);
        
        RenderTexture.ReleaseTemporary(coc);
        RenderTexture.ReleaseTemporary(dof0);
        RenderTexture.ReleaseTemporary(dof1);
    }
}