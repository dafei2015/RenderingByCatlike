#region 引用

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

#endregion

public class CustomShaderGUI22 : ShaderGUI
{
    enum SmoothnessSource
    {
        Uniform,
        Albedo,
        Metallic
    }

    enum RenderingMode
    {
        Opaque,
        Cutout,
        Fade,
        Transparent
    }
    
    enum TessellationMode 
    {
        Uniform,
        Edge
    }

    struct RenderingSettings
    {
        public RenderQueue queue;
        public string renderType;
        public BlendMode srcBlend, dstBlend;
        public bool zWrite;

        public static RenderingSettings[] modes =
        {
            new RenderingSettings
            {
                queue = RenderQueue.Geometry,
                renderType = "",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings
            {
                queue = RenderQueue.AlphaTest,
                renderType = "TransparentCutout",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.Zero,
                zWrite = true
            },
            new RenderingSettings
            {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.SrcAlpha,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            },
            new RenderingSettings
            {
                queue = RenderQueue.Transparent,
                renderType = "Transparent",
                srcBlend = BlendMode.One,
                dstBlend = BlendMode.OneMinusSrcAlpha,
                zWrite = false
            },
        };
    }

    Material _target;
    MaterialEditor _editor;
    MaterialProperty[] _properties;
    static GUIContent _staticLabel = new GUIContent();

    private SmoothnessSource _source;
    RenderingMode _mode;
    TessellationMode _tessellationMode;
    bool _shouldShowAlphaCutoff;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _target = materialEditor.target as Material;
        _editor = materialEditor;
        _properties = properties;

        DoRenderingMode();
        if (_target.HasProperty("_TessellationUniform")) 
            DoTessellation();
        if (_target.HasProperty("_WireframeColor")) 
            DoWireframe();
        
        DOMain();
        DoSecondary();
        // DoAdvanced();
    }

    void DoTessellation()
    {
        GUILayout.Label("Tessellation",EditorStyles.boldLabel);
        EditorGUI.indentLevel +=2;
        
        if(IsKeywordEnabled("_TESSELLATION_EDGE"))
            _tessellationMode = TessellationMode.Edge;
        EditorGUI.BeginChangeCheck();
        
        _tessellationMode = (TessellationMode)EditorGUILayout.EnumPopup(MakeLabel("Mode"),_tessellationMode);
        if(EditorGUI.EndChangeCheck())
        {
            RecordAction("Tessellation Mode");
            SetKeyword("_TESSELLATION_EDGE",_tessellationMode == TessellationMode.Edge);
        }
        if(_tessellationMode == TessellationMode.Uniform)
            _editor.ShaderProperty(FindProperty("_TessellationUniform"),MakeLabel("Uniform"));
        else
        {
            _editor.ShaderProperty(FindProperty("_TessellationEdgeLength"),MakeLabel("Edge Length"));
        }
        EditorGUI.indentLevel -=2;
    }
    void DoWireframe()
    {
        GUILayout.Label("Wireframe", EditorStyles.boldLabel);
        EditorGUI.indentLevel += 2;
        _editor.ShaderProperty(FindProperty("_WireframeColor"), MakeLabel("Color"));
        _editor.ShaderProperty(FindProperty("_WireframeSmoothing"), MakeLabel("Smoothing", "In screen space."));
        _editor.ShaderProperty(FindProperty("_WireframeThickness"), MakeLabel("Thickness", "In screen space."));
        EditorGUI.indentLevel -= 2;
    }

    // private void DoAdvanced()
    // {
    //     GUILayout.Label("Advanced Options", EditorStyles.boldLabel);
    //     _editor.EnableInstancingField();
    // }

    private void DoRenderingMode()
    {
        if (IsKeywordEnabled("_RENDERING_CUTOUT"))
        {
            _shouldShowAlphaCutoff = true;
            _mode = RenderingMode.Cutout;
        }
        else if (IsKeywordEnabled("_RENDERING_FADE"))
        {
            _mode = RenderingMode.Fade;
        }
        else if (IsKeywordEnabled("_RENDERING_TRANSPARENT"))
        {
            _mode = RenderingMode.Transparent;
        }

        EditorGUI.BeginChangeCheck();
        _mode = (RenderingMode)EditorGUILayout.EnumPopup(MakeLabel("Rendering Mode"), _mode);
        if (EditorGUI.EndChangeCheck())
        {
            _shouldShowAlphaCutoff = _mode == RenderingMode.Cutout;
            RecordAction("Rendering Mode");
            SetKeyword("_RENDERING_CUTOUT", _mode == RenderingMode.Cutout);
            SetKeyword("_RENDERING_FADE", _mode == RenderingMode.Fade);
            SetKeyword("_RENDERING_TRANSPARENT", _mode == RenderingMode.Transparent);

            RenderingSettings settings = RenderingSettings.modes[(int)_mode];
            foreach (Material m in _editor.targets)
            {
                m.renderQueue = (int)settings.queue;
                m.SetOverrideTag("RenderType", settings.renderType);
                m.SetInt("_SrcBlend", (int)settings.srcBlend);
                m.SetInt("_DstBlend", (int)settings.dstBlend);
                m.SetInt("_ZWrite", settings.zWrite ? 1 : 0);
            }
        }

        if (_mode == RenderingMode.Fade || _mode == RenderingMode.Transparent)
        {
            DoSemitransparentShadows();
        }
    }

    private void DoSemitransparentShadows()
    {
        EditorGUI.BeginChangeCheck();
        bool semitransparentShadows = EditorGUILayout.Toggle(MakeLabel("Semitransp.Shadows", "Semitransparent Shadows"), IsKeywordEnabled("_SEMITRANSPARENT_SHADOWS"));
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_SEMITRANSPARENT_SHADOWS", semitransparentShadows);
            _shouldShowAlphaCutoff = !semitransparentShadows;
        }
    }


    #region MainTexture

    private void DOMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        MaterialProperty tint = FindProperty("_Color");
        _editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, tint);

        if (_shouldShowAlphaCutoff)
            DoAlphaCutoff();
        DoMetallic();
        DoSmoothness();
        DoNormals();
        DoParallax();
        DoOcclusion();
        DoEmission();
        DoDetailMask();

        _editor.TextureScaleOffsetProperty(mainTex);
    }

    private void DoAlphaCutoff()
    {
        MaterialProperty slider = FindProperty("_Cutoff");
        EditorGUI.indentLevel += 2;
        _editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel -= 2;
    }


    private void DoMetallic()
    {
        MaterialProperty map = FindProperty("_MetallicMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(map, "Metallic (R)"), map, tex ? null : FindProperty("_Metallic"));
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_METALLIC_MAP", map.textureValue);
    }

    private void DoSmoothness()
    {
        if (IsKeywordEnabled("_SMOOTHNESS_ALBEDO"))
            _source = SmoothnessSource.Albedo;
        else if (IsKeywordEnabled("_SMOOTHNESS_METALLIC"))
            _source = SmoothnessSource.Metallic;

        MaterialProperty slider = FindProperty("_Smoothness");
        EditorGUI.indentLevel += 2;
        _editor.ShaderProperty(slider, MakeLabel(slider));
        EditorGUI.indentLevel += 1;

        EditorGUI.BeginChangeCheck();
        _source = (SmoothnessSource)EditorGUILayout.EnumPopup(MakeLabel("Source"), _source);
        if (EditorGUI.EndChangeCheck())
        {
            RecordAction("Smoothness Source");
            SetKeyword("_SMOOTHNESS_ALBEDO", _source == SmoothnessSource.Albedo);
            SetKeyword("_SMOOTHNESS_METALLIC", _source == SmoothnessSource.Metallic);
        }

        EditorGUI.indentLevel -= 3;
    }


    private void DoNormals()
    {
        MaterialProperty map = FindProperty("_NormalMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(map), map, tex ? FindProperty("_BumpScale") : null);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_NORMAL_MAP", map.textureValue);
        }
    }

    private void DoParallax()
    {
        MaterialProperty map = FindProperty("_ParallaxMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(map, "Parallax (G)"), map, tex ? FindProperty("_ParallaxStrength") : null);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_PARALLAX_MAP", map.textureValue);
    }

    private void DoOcclusion()
    {
        MaterialProperty map = FindProperty("_OcclusionMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(map, "Occlusion (G)"), map, tex ? FindProperty("_OcclusionStrength") : null);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_OCCLUSION_MAP", map.textureValue);
    }

    private void DoEmission()
    {
        MaterialProperty map = FindProperty("_EmissionMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertyWithHDRColor(MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"), false);
        // _editor.TexturePropertyWithHDRColor(
        // MakeLabel(map, "Emission (RGB)"), map, FindProperty("_Emission"),
        // emissionConfig, false
        // );
        _editor.LightmapEmissionProperty(2);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            if (tex != map.textureValue)
                SetKeyword("_EMISSION_MAP", map.textureValue);

            foreach (Material material in _editor.targets)
            {
                material.globalIlluminationFlags &= ~MaterialGlobalIlluminationFlags.EmissiveIsBlack;
            }
        }
    }

    private void DoDetailMask()
    {
        MaterialProperty mask = FindProperty("_DetailMask");
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(mask, "Detail Mask (A)"), mask);
        if (EditorGUI.EndChangeCheck())
            SetKeyword("_DETAIL_MASK", mask.textureValue);
    }

    #endregion

    #region SecondTexture

    private void DoSecondary()
    {
        GUILayout.Label("Secondary Maps", EditorStyles.boldLabel);

        MaterialProperty detailTex = FindProperty("_DetailTex");

        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(detailTex, "Albedo (RGB) multiplied by 2"), detailTex);
        if (EditorGUI.EndChangeCheck())
        {
            SetKeyword("_DETAIL_ALBEDO_MAP", detailTex.textureValue);
        }

        DoSecondaryNormals();
        _editor.TextureScaleOffsetProperty(detailTex);
    }

    private void DoSecondaryNormals()
    {
        MaterialProperty map = FindProperty("_DetailNormalMap");
        Texture tex = map.textureValue;
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel(map), map, tex ? FindProperty("_DetailBumpScale") : null);
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
        {
            SetKeyword("_DETAIL_NORMAL_MAP", map.textureValue);
        }
    }

    #endregion

    private MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, _properties);
    }

    private static GUIContent MakeLabel(string text, string tooltip = null)
    {
        _staticLabel.text = text;
        _staticLabel.tooltip = tooltip;
        return _staticLabel;
    }

    private static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        _staticLabel.text = property.displayName;
        _staticLabel.tooltip = tooltip;
        return _staticLabel;
    }

    private void SetKeyword(string keyword, bool state)
    {
        if (state)
        {
            foreach (Material target in _editor.targets)
            {
                target.EnableKeyword(keyword);
            }
        }
        else
        {
            foreach (Material target in _editor.targets)
            {
                target.DisableKeyword(keyword);
            }
        }
    }

    private bool IsKeywordEnabled(string keyword)
    {
        return _target.IsKeywordEnabled(keyword);
    }

    private void RecordAction(string label)
    {
        _editor.RegisterPropertyChangeUndo(label);
    }
}