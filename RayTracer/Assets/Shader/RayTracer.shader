Shader "Custom/RayTracer"
{
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#include "UnityCG.cginc"

            // Die Struktur, die die UV-Daten und Positionen enthält
            struct appdata_t {
                float4 vertex : POSITION;   // Vertex-Position
                float2 texcoord : TEXCOORD0; // UV-Koordinaten
            };
            // Struct to describe 
            struct v2f {
                float4 pos : SV_POSITION;   // Position im Clip-Space
                float2 uv : TEXCOORD0;      // UV-Koordinaten
            };

            /* ViewParams with the params of the near plane
             * Distance of the cam to the near plane
             * Height of the near plane
             * Width of the near plane
             */
            float3 ViewParams;
            
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
            float4x4 CamLocalToWorldMatrix;


            // Struct to describe a Ray
            struct Ray{
                float3 origin;          // The origin of a ray as a 3d vector.
                float3 direction;       // The direction of a ray as a 3d vector.
            };

            // Struct to determine a Hit with its properties
            struct RayHit{
                bool isHit;             // True when Ray has hit an object.
                float distance;         // The distance where the ray has hit an object from the origin.
                float3 hitPoint;        // The hitpoint in 3d coordinates.
                float3 normalVector;    // The normal vector at the hitpoint.
            };

            // Struct to determine a material for the raytracing
			struct RayTracingMaterial
			{
				float4 colour;
				float4 emissionColour;
				float4 specularColour;
				float emissionStrength;
				float smoothness;
				float specularProbability;
				int flag;
			};

            // Struct to describe a Sphereobject
            struct Sphere
            {
                float3 center;
                float radius;
                RayTracingMaterial material;
            };

            StructuredBuffer<Sphere> Spheres;
            int NumSpheres;

            // The Vertex-Shader
            v2f vert(appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Berechnung der Position im Clip-Space
                o.uv = v.texcoord; // Übertragung der UV-Koordinaten
                return o;
            }

            struct ClosestHit{
                RayHit hitInformation;
                Sphere hittedSphere;
            };

            RayHit HitSphere(Ray ray, Sphere sphere) {
                RayHit rayHit;
                rayHit.isHit = false;

                // Vector from ray origin to sphere center
                float3 oc = ray.origin - sphere.center;

                // Quadratic coefficients
                float a = dot(ray.direction, ray.direction);
                float b = 2.0f * dot(oc, ray.direction);
                float c = dot(oc, oc) - (sphere.radius * sphere.radius);

                // Discriminant
                float discriminant = b * b - 4.0f * a * c;

                if (discriminant < 0) {
                    return rayHit; // No intersection
                }

                float t = (-b - sqrt(discriminant)) / (2 * a);

                // Populate RayHit
                rayHit.isHit = true;
                rayHit.distance = t;
                rayHit.hitPoint = ray.origin + t * ray.direction;
                rayHit.normalVector = normalize(rayHit.hitPoint - sphere.center);
                return rayHit;
            }


            // Function to calculate the nearest collision of a ray and a sphere.
            ClosestHit CalculateNearestCollision(Ray ray){
                
                ClosestHit closestHit;
                closestHit.hitInformation.isHit = false;                                // Initialize with no hit
                float shortestHitLength = 1.#INF;                                       // Sets the disctance to the closest hit to a very high number.
                
                //Iterate trough all Spheres
                for(int i = 0 ; i < NumSpheres; i++){
                             
                   Sphere currentSphere = Spheres[i];
                   RayHit actualHit = HitSphere(ray, currentSphere);                    // Calculate the hit information of the current ray to the current sphere

                   if(actualHit.isHit && actualHit.distance < shortestHitLength){       // Checks if the Object is hit and if the hit was the closest one since begin of the rendering.
                       shortestHitLength = actualHit.distance;          
                       closestHit.hitInformation = actualHit;
                       closestHit.hittedSphere = currentSphere;
                   }                           
                }
                return closestHit;                                                      // Returns the Hitinformation of the hit with the closest distance.
            }

            // The shader that represents the ray tracer.
            // Returns the color value of each corresponding pixel. 
            float4 frag (v2f i) : SV_Target
            {
                float3 viewPointLocal = float3(i.uv - 0.5, 1) * ViewParams;
                float3 viewPoint = mul(CamLocalToWorldMatrix, float4(viewPointLocal, 1));

                Ray ray;
                ray.origin = _WorldSpaceCameraPos;
                ray.direction = normalize(viewPoint - ray.origin);

                ClosestHit closestHit = CalculateNearestCollision(ray);          
                if (closestHit.hitInformation.isHit) {
                    return closestHit.hittedSphere.material.colour; 
                } else {
                    return float4(0, 0, 0, 1);
                }

            }
            ENDCG
        }
    }
}
