﻿using System;
using System.Collections.Generic;
using UnityEngine;
using static UnityEngine.Mathf;

[ExecuteAlways, ImageEffectAllowedInSceneView]
public class RayTracerManager : MonoBehaviour
{
    [SerializeField] bool useShaderInSceneView;
    [SerializeField] Shader selectedShader;
    [SerializeField] int maxBounces;
    [SerializeField] int raysPerPixel;

    [SerializeField] int frameNumber;

    Material material;

    ComputeBuffer sphereBuffer;

    RenderTexture prevFrame;

    private void Start()
    {
    }

    /// <summary>
    /// Function to send the data to the shader and render the picture with the new selected shader e.g. the raytracer.
    /// </summary>
    /// <param name="source"></param>
    /// <param name="destination"></param>
    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        Camera cam = Camera.current;
        

        if (cam.name != "SceneCamera" || useShaderInSceneView)
        {

            ShaderHelper.InitMaterial(selectedShader, ref material); // Set up the material with the ray tracing shader.
            CreateSpheres();

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

            frameNumber = Time.frameCount;
            prevFrame = RenderTexture.GetTemporary(source.width, source.height);


            // Set fields of the raytracing material, so that the shader can use it.
            material.SetVector("ViewParams", new Vector3(nearPlaneWidth, nearPlaneHeight, nearClipPlane));
            material.SetMatrix("CamLocalToWorldMatrix", camTransformationMatrix);
            material.SetInt("MaxBounces", maxBounces);
            material.SetInt("RaysPerPixel", raysPerPixel);
            material.SetTexture("PreviousFrame", prevFrame);
            material.SetInt("FrameNumber", frameNumber);


            Graphics.Blit(null, destination, material);
            RenderTexture.ReleaseTemporary(prevFrame);
        }
        else {
            Graphics.Blit(source, destination);
        }
    }

    /// <summary>
    /// Adopted from Sebastian League project.
    /// Function to Create the Spheres from the buffer transfered from the unity engine.
    /// Sends the SPheres to the shader, where the shader can work with it.
    /// </summary>
    void CreateSpheres()
    {
        RayTracedSphere[] sphereObjects = FindObjectsByType<RayTracedSphere>(FindObjectsSortMode.None);
        Sphere[] spheres = new Sphere[sphereObjects.Length];

        for (int i = 0; i < sphereObjects.Length; i++)
        {
            spheres[i] = new Sphere()
            {
                center = sphereObjects[i].transform.position,
                radius = sphereObjects[i].transform.localScale.x * 0.5f,
                material = sphereObjects[i].material
            };
        }

        // Create buffer containing all sphere data, and send it to the shader
        ShaderHelper.CreateStructuredBuffer(ref sphereBuffer, spheres);
        material.SetBuffer("Spheres", sphereBuffer);
        material.SetInt("NumSpheres", sphereObjects.Length);
    }

}
