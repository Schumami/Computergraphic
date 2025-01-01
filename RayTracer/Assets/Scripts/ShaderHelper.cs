using UnityEngine;
using static UnityEngine.Mathf;

static public class ShaderHelper
{
    /// <summary>
    /// Adopted from Sebastian League project.
    /// Function to ensure that materials are initialized with shaders consistently and efficiently, e.g. B. when dynamically creating objects or loading assets.
    /// A material is always initialized with the correct shader.
    /// A default shader is used if none is specified.
    /// A material is recreated only when necessary (e.g. if it does not already exist or has an incorrect shader assigned).
    /// </summary>
    /// <param name="shader">The shader to use for the material. It is a reference to a shader object.</param>
    /// <param name="mat">A reference to a Material object that is either newly created or updated.</param>
    static public void InitMaterial(Shader shader, ref Material mat)
    {
        if (mat == null || (mat.shader != shader && shader != null))
        {
            if (shader == null)
            {
                shader = Shader.Find("Unlit/Texture");
            }

            mat = new Material(shader);
        }
    }

    /// <summary>
    /// Adopted from Sebastian League project.
    /// Create a compute buffer containing the given data (Note: data must be blittable)
    /// </summary>
    /// <typeparam name="T"></typeparam>
    /// <param name="buffer"></param>
    /// <param name="data"></param>
    public static void CreateStructuredBuffer<T>(ref ComputeBuffer buffer, T[] data) where T : struct
    {
        // Cannot create 0 length buffer (not sure why?)
        int length = Max(1, data.Length);
        // The size (in bytes) of the given data type
        int stride = System.Runtime.InteropServices.Marshal.SizeOf(typeof(T));

        // If buffer is null, wrong size, etc., then we'll need to create a new one
        if (buffer == null || !buffer.IsValid() || buffer.count != length || buffer.stride != stride)
        {
            if (buffer != null) { buffer.Release(); }
            buffer = new ComputeBuffer(length, stride, ComputeBufferType.Structured);
        }

        buffer.SetData(data);
    }

}
