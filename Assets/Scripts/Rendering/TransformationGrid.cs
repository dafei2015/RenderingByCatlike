﻿#region 引用

using System.Collections.Generic;
using UnityEngine;

#endregion

public class TransformationGrid : MonoBehaviour
{
    public Transform prefab;
    public int gridResolution = 10;

    private Transform[] grid;

    private Matrix4x4 transformation;
    private List<Transformation> transformations;

    private void Awake()
    {
        grid = new Transform[gridResolution * gridResolution * gridResolution];
        for (int i = 0, z = 0; z < gridResolution; z++)
        for (var y = 0; y < gridResolution; y++)
        for (var x = 0; x < gridResolution; x++, i++)
            grid[i] = CreateGridPoint(x, y, z);

        transformations = new List<Transformation>();
    }

    private void Update()
    {
        UpdateTransformation();
        for (int i = 0, z = 0; z < gridResolution; z++)
        for (var y = 0; y < gridResolution; y++)
        for (var x = 0; x < gridResolution; x++, i++)
            grid[i].localPosition = TransformPoint(x, y, z);
    }

    private void UpdateTransformation()
    {
        GetComponents(transformations);
        if (transformations.Count > 0)
        {
            transformation = transformations[0].Matrix;
            for (var i = 1; i < transformations.Count; i++) transformation = transformations[i].Matrix * transformation;
        }
    }

    private Vector3 TransformPoint(int x, int y, int z)
    {
        var coordinates = GetCoordinates(x, y, z);
        // for (int i = 0; i < transformations.Count; i++)
        // {
        //     coordinates = transformations[i].Apply(coordinates);
        // }
        return transformation.MultiplyPoint(coordinates);
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