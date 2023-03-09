using UnityEngine;

public class GPUInstancingTest : MonoBehaviour
{
    public Transform Prefab;
    public int Instances = 5000;

    public float Radius = 50f;
    void Start()
    {
        MaterialPropertyBlock properties = new MaterialPropertyBlock();

        for (int i = 0; i < Instances; i++)
        {
            Transform t = Instantiate(Prefab, transform, true);
            t.localPosition = Random.insideUnitSphere * Radius;

            // t.GetComponent<Renderer>().material.color = new Color(Random.value, Random.value, Random.value);
            properties.SetColor("_Color",new Color(Random.value,Random.value,Random.value));
            
            MeshRenderer r = t.GetComponent<MeshRenderer>();
            if(r)
            {
                r.SetPropertyBlock(properties);
            }
            else
            {
                for (int j = 0; j < t.childCount; j++)
                {
                    r = t.GetChild(j).GetComponent<MeshRenderer>();
                    if(r)
                        r.SetPropertyBlock(properties);
                }
            }
        }
       
    }
}
