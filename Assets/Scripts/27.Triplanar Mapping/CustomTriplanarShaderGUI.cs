#region 引用

using UnityEditor;
using UnityEngine;

#endregion

public class CustomTriplanarShaderGUI : CustomBaseShaderGUI
{
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        base.OnGUI(materialEditor, properties);
        _editor.ShaderProperty(FindProperty("_MapScale"), MakeLabel("Map Scale"));

        DoMaps();
        DoBlending();
        DoOtherSettings();
    }

    private void DoMaps()
    {
        GUILayout.Label("Top Maps", EditorStyles.boldLabel);

        MaterialProperty topAlbedo = FindProperty("_TopMainTex");
        Texture topTexture = topAlbedo.textureValue;
        
        EditorGUI.BeginChangeCheck();
        _editor.TexturePropertySingleLine(MakeLabel("Albedo"), topAlbedo);
        
        if (EditorGUI.EndChangeCheck() && topTexture != topAlbedo.textureValue) 
        {
            SetKeyword("_SEPARATE_TOP_MAPS", topAlbedo.textureValue);
        }
        
        _editor.TexturePropertySingleLine(MakeLabel("MOHS", "Metallic (R) Occlusion (G) Height (B) Smoothness (A)"), FindProperty("_TopMOHSMap"));
        _editor.TexturePropertySingleLine(MakeLabel("Normals"), FindProperty("_TopNormalMap"));
        
        GUILayout.Label("Maps", EditorStyles.boldLabel);

        _editor.TexturePropertySingleLine(MakeLabel("Albedo"), FindProperty("_MainTex"));
        _editor.TexturePropertySingleLine(MakeLabel("MOHS", "Metallic (R) Occlusion (G) Height (B) Smoothness (A)"), FindProperty("_MOHSMap"));
        _editor.TexturePropertySingleLine(MakeLabel("Normals"), FindProperty("_NormalMap"));
    }

    private void DoBlending()
    {
        GUILayout.Label("Blending", EditorStyles.boldLabel);

        _editor.ShaderProperty(FindProperty("_BlendOffset"), MakeLabel("Offset"));
        _editor.ShaderProperty(FindProperty("_BlendExponent"), MakeLabel("Exponent"));
        _editor.ShaderProperty(FindProperty("_BlendHeightStrength"), MakeLabel("Height Strength"));
    }

    private void DoOtherSettings()
    {
        GUILayout.Label("Other Settings", EditorStyles.boldLabel);

        _editor.RenderQueueField();
        _editor.EnableInstancingField();
    }
}