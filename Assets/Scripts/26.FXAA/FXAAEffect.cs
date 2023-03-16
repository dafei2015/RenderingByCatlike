#region 引用

using System;
using UnityEngine;

#endregion

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class FXAAEffect : MonoBehaviour
{
    [HideInInspector] public Shader FxaaShader;
    [NonSerialized] Material _fxaa;
    
    public enum LuminanceMode{Alpha,Green,Calculate}
    
    public LuminanceMode LuminanceSource;
    
    [Range(0.0312f,0.0833f)]
    public float ContrastThreshold = 0.0312f;
    
    [Range(0.063f, 0.333f)]
    public float RelativeThreshold = 0.063f;
    
    [Range(0,1f)]
    public float SubPixelBlending = 1f;
    
    public bool LowQuality;
    
    public bool GammaBlending;
    
    const int LuminancePass =0;
    const int FxaaPass =1;
    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_fxaa == null)
        {
            _fxaa = new Material(FxaaShader);
            _fxaa.hideFlags = HideFlags.HideAndDontSave;
        }
        
        _fxaa.SetFloat("_ContrastThreshold",ContrastThreshold);
        _fxaa.SetFloat("_RelativeThreshold",RelativeThreshold);
        _fxaa.SetFloat("_SubPixelBlending",SubPixelBlending);
        
        if(LowQuality)
        {
            _fxaa.EnableKeyword("LOW_QUALITY");
        }
        else
        {
            _fxaa.DisableKeyword("LOW_QUALITY");
        }
        
        if(GammaBlending)
        {
            _fxaa.EnableKeyword("GAMMA_BLENDING");
        }
        else
        {
            _fxaa.DisableKeyword("GAMMA_BLENDING");
        }
        if(LuminanceSource == LuminanceMode.Calculate)
        {
            _fxaa.DisableKeyword("LUMINANCE_GREEN");
            RenderTexture luminanceTex = RenderTexture.GetTemporary(src.width,src.height,0,src.format);
            Graphics.Blit(src,luminanceTex,_fxaa,LuminancePass);
            Graphics.Blit(luminanceTex,dest,_fxaa,FxaaPass);
            RenderTexture.ReleaseTemporary(luminanceTex);
        }
        else
        {
            if(LuminanceSource == LuminanceMode.Green)
            {
                _fxaa.EnableKeyword("LUMINANCE_GREEN");
            }
            else
            {
                _fxaa.DisableKeyword("LUMINANCE_GREEN");
            }
            Graphics.Blit(src, dest,_fxaa,FxaaPass);
        }
    }
}