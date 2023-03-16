#region 引用

using UnityEditor;
using UnityEngine;

#endregion

public class CustomBaseShaderGUI : ShaderGUI
{
    protected Material _target;
    protected MaterialEditor _editor;
    MaterialProperty[] _properties;
    static GUIContent _staticLabel = new GUIContent();
    
    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        _target = materialEditor.target as Material;
        _editor = materialEditor;
        _properties = properties;
    }


    protected MaterialProperty FindProperty(string name)
    {
        return FindProperty(name, _properties);
    }

    protected static GUIContent MakeLabel(string text, string tooltip = null)
    {
        _staticLabel.text = text;
        _staticLabel.tooltip = tooltip;
        return _staticLabel;
    }

    protected static GUIContent MakeLabel(MaterialProperty property, string tooltip = null)
    {
        _staticLabel.text = property.displayName;
        _staticLabel.tooltip = tooltip;
        return _staticLabel;
    }

    protected void SetKeyword(string keyword, bool state)
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

    protected bool IsKeywordEnabled(string keyword)
    {
        return _target.IsKeywordEnabled(keyword);
    }

    protected void RecordAction(string label)
    {
        _editor.RegisterPropertyChangeUndo(label);
    }
}