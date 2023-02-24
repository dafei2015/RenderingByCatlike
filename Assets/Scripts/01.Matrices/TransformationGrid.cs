#region 引用

using System.Collections.Generic;
using UnityEngine;

#endregion

public class TransformationGrid : MonoBehaviour
{
    public Transform prefab;
    public int gridResolution = 10;

    private Transform[] _grid;

    private Matrix4x4 _transformation;
    private List<Transformation> _transformations;

    private void Awake()
    {
        _grid = new Transform[gridResolution * gridResolution * gridResolution];
        for (int i = 0, z = 0; z < gridResolution; z++)
        for (var y = 0; y < gridResolution; y++)
        for (var x = 0; x < gridResolution; x++, i++)
            _grid[i] = CreateGridPoint(x, y, z);

        _transformations = new List<Transformation>();
    }

    private void Update()
    {
        UpdateTransformation();
        for (int i = 0, z = 0; z < gridResolution; z++)
        for (var y = 0; y < gridResolution; y++)
        for (var x = 0; x < gridResolution; x++, i++)
            _grid[i].localPosition = TransformPoint(x, y, z);
    }

    private void UpdateTransformation()
    {
        GetComponents(_transformations);
        if (_transformations.Count > 0)
        {
            _transformation = _transformations[0].Matrix;
            for (var i = 1; i < _transformations.Count; i++) _transformation = _transformations[i].Matrix * _transformation;
        }
    }

    private Vector3 TransformPoint(int x, int y, int z)
    {
        var coordinates = GetCoordinates(x, y, z);
        // for (int i = 0; i < transformations.Count; i++)
        // {
        //     coordinates = transformations[i].Apply(coordinates);
        // }
        return _transformation.MultiplyPoint(coordinates);
    }

    private Transform CreateGridPoint(int x, int y, int z)
    {
        var point = Instantiate(prefab);
        point.localPosition = GetCoordinates(x, y, z);
        point.GetComponent<MeshRenderer>().material.color = new Color((float)x / gridResolution, (float)y / gridResolution, (float)z / gridResolution);
        return point;
    }

    private Vector3 GetCoordinates(int x, int y, int z)
    {
        return new(x - (gridResolution - 1) * 0.5f, y - (gridResolution - 1) * 0.5f, z - (gridResolution - 1) * 0.5f);
    }
}