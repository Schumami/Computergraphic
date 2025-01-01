using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class RayTracedSphere : MonoBehaviour
{
	public RayTracingMaterial material;

	[SerializeField, HideInInspector] bool materialInitFlag;
    [SerializeField, HideInInspector] int materialObjectID;

    void OnValidate()
	{
		if (!materialInitFlag)
		{
			materialInitFlag = true;
			material.SetDefaultValues();
		}
	}
}