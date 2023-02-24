#region 引用

using UnityEditor;
using UnityEngine;

#endregion

public class CustomShaderGUI : ShaderGUI
{
    enum SmoothnessSource
    {
        Uniform,
        Albedo,
        Metallic
    }

    Material _target;
    MaterialEditor _editor;
    MaterialProperty[] _properties;
    static GUIContent _staticLabel = new GUIContent();

    SmoothnessSource _source;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _target = materialEditor.target as Material;
        _editor = materialEditor;
        _properties = properties;

        DOMain();
        DoSecondary();
    }


    #region MainTexture

    private void DOMain()
    {
        GUILayout.Label("Main Maps", EditorStyles.boldLabel);

        MaterialProperty mainTex = FindProperty("_MainTex");
        MaterialProperty tint = FindProperty("_Tint");
        _editor.TexturePropertySingleLine(MakeLabel(mainTex, "Albedo (RGB)"), mainTex, tint);
        DoMetallic();
        DoSmoothness();
        DoNormals();
        DoOcclusion();
        DoEmission();
        DoDetailMask();
        _editor.TextureScaleOffsetProperty(mainTex);
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
        if (EditorGUI.EndChangeCheck() && tex != map.textureValue)
            SetKeyword("_EMISSION_MAP", map.textureValue);
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
        if (EditorGUI.EndChangeCheck()&& tex != map.textureValue)
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