#region 引用

using System;
using UnityEngine;

#endregion

[ExecuteInEditMode, ImageEffectAllowedInSceneView]
public class BloomEffect : MonoBehaviour
{
    public Shader BloomShader;

    [Range(0, 10)] public float Intensity = 1;
    [Range(1, 16)] public int iterations = 1;
    [Range(0, 10)] public float Threshold = 1;
    [Range(0, 1)] public float SoftThreshold = 0.5f;

    public bool Debug;
    RenderTexture[] _textures = new RenderTexture[16];
    [NonSerialized] Material _bloom;

    const int BoxDownPrefilterPass = 0;
    const int BoxDownPass = 1;
    const int BoxUpPass = 2;
    const int ApplyBloomPass = 3;
    const int DebugBloomPass = 4;

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (_bloom == null)
        {
            _bloom = new Material(BloomShader);
            _bloom.hideFlags = HideFlags.HideAndDontSave;
        }

        float knee = Threshold * SoftThreshold;
        Vector4 filter;
        filter.x = Threshold;
        filter.y = filter.x - knee;
        filter.z = 2f * knee;
        filter.w = 0.25f / (knee + 0.00001f);
        _bloom.SetVector("_Filter", filter);
        _bloom.SetFloat("_Intensity", Mathf.GammaToLinearSpace(Intensity));
        int width = src.width / 2;
        int height = src.height / 2;
        RenderTextureFormat format = src.format;

        RenderTexture currentDestination = _textures[0] = RenderTexture.GetTemporary(width, height, 0, format);
        Graphics.Blit(src, currentDestination, _bloom, BoxDownPrefilterPass);

        RenderTexture currentSource = currentDestination;

        int i = 1;
        for (; i < iterations; i++)
        {
            width /= 2;
            height /= 2;
            if (height < 2)
                break;

            currentDestination = _textures[i] = RenderTexture.GetTemporary(width, height, 0, format);
            Graphics.Blit(currentSource, currentDestination, _bloom, BoxDownPass);
            // RenderTexture.ReleaseTemporary(currentSource);
            currentSource = currentDestination;
        }

        for (i -= 2; i >= 0; i--)
        {
            currentDestination = _textures[i];
            _textures[i] = null;
            Graphics.Blit(currentSource, currentDestination, _bloom, BoxUpPass);
            RenderTexture.ReleaseTemporary(currentSource);
            currentSource = currentDestination;
        }

        if (Debug)
        {
            Graphics.Blit(currentSource, dest, _bloom, DebugBloomPass);
        }
        else
        {
            _bloom.SetTexture("_SourceTex", src);
            Graphics.Blit(currentSource, dest, _bloom, ApplyBloomPass);
        }

        RenderTexture.ReleaseTemporary(currentSource);
    }
}