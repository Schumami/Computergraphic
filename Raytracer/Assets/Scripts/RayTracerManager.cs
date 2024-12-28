﻿using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;

[ExecuteAlways, ImageEffectAllowedInSceneView]
public class RayTracerManager : MonoBehaviour
{
    [SerializeField] bool useShaderInSceneView;
    [SerializeField] Shader selectedShader;

    Material material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Camera cam = Camera.current;

        if (cam.name != "SceneCamera" || useShaderInSceneView)
        {
            ShaderHelper.InitMaterial(selectedShader, ref material); // Set up the material with the ray tracing shader.
            // Calculate the near plane (Projektionsfläche) based on de FOV and distance.
            float nearClipPlane = cam.nearClipPlane; // Distance of the cam to the near plane
            float nearPlaneHeight = nearClipPlane * Tan(cam.fieldOfView * 0.5f * Deg2Rad) * 2; // Height of the near plane
            float nearPlaneWidth = nearPlaneHeight * cam.aspect; // Width of the near plane

            /*      World transformation matrix
             *      Gives information about position, scale and rotation of the cam in reference to the world.
             *         Right Up  Forward Position
             *      ┌                               ┐
             * X    |   VRx  VUx   VFx     PosX     |
             * Y    |   VRy  VUy   VFy     PosY     |
             * Z    |   VRz  VUz   VFz     PosZ     |
             * H    |    0    0     0       1       |
             *      └                               ┘
             */
            Matrix4x4 camTransformationMatrix = cam.transform.localToWorldMatrix; 

            // Set fields of the raytracing material, so that the shader can use it.
            material.SetVector("ViewParams", new Vector3(nearPlaneWidth, nearPlaneHeight, nearClipPlane));
            material.SetMatrix("CamLocalToWorldMatrix", camTransformationMatrix);
            
            Graphics.Blit(null, destination, material);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }

}
