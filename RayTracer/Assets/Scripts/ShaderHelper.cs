using UnityEngine;

static public class ShaderHelper
{
    /// <summary>
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
}
