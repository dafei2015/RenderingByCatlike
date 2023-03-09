using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EmissiveOscillator : MonoBehaviour
{
    MeshRenderer _emissiveRenderer;
    Material _emissiveMaterial;
    // Start is called before the first frame update
    void Start()
    {
        _emissiveRenderer = GetComponent<MeshRenderer>();
        _emissiveMaterial = _emissiveRenderer.material;
    }

    // Update is called once per frame
    void Update()
    {
        Color color = Color.Lerp(Color.white, Color.black, Mathf.Sin(Time.time*Mathf.PI) *0.5f+0.5f);
        _emissiveMaterial.SetColor("_Emission",color);
        // _emissiveRenderer.UpdateGIMaterials(); //通知实时 GI 系统,此时Emission属性选择realtime  比较复杂的用UpdateGIMaterials
        DynamicGI.SetEmissive(_emissiveRenderer,color);  // 纯色使用DynamicGI.SetEmissive实现
    }
}
