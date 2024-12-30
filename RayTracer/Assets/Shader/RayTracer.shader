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

            struct v2f {
                float4 pos : SV_POSITION;   // Position im Clip-Space
                float2 uv : TEXCOORD0;      // UV-Koordinaten
            };

            float3 ViewParams;
            float4x4 CamLocalToWorldMatrix;

            struct Ray{
                float3 origin;
                float3 direction;
            };

            struct RayHit{
                bool isHit;
                float distance;
                float3 hitPoint;
                float3 normalVector;
            };

            struct RayTracingMaterial{
                float4 color;
            };

            struct Sphere
            {
                float3 center;
                float radius;
                RayTracingMaterial material;
            };

            StructuredBuffer<Sphere> Spheres;
            int numSpheres;

            // Der Vertex-Shader
            v2f vert(appdata_t v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex); // Berechnung der Position im Clip-Space
                o.uv = v.texcoord; // Übertragung der UV-Koordinaten
                return o;
            }

            RayHit HitSphere(Ray ray, Sphere sphere) {
                RayHit rayHit;
                rayHit.isHit = false;

                // Center the Sphere for the calculation
                float3 oc = ray.origin - sphere.center;

                // Calculate A, B, and C
                float a = dot(ray.direction, ray.direction); // v_x^2 + v_y^2 + v_z^2
                float b = 2.0f * dot(oc, ray.direction);    // 2 * ((x_0 - x_m) * v_x + (y_0 - y_m) * v_y + (z_0 - z_m) * v_z)
                float c = dot(oc, oc) - (sphere.radius * sphere.radius); // (x_0 - x_m)^2 + (y_0 - y_m)^2 + (z_0 - z_m)^2 - r^2

                // Calculate the discriminant
                float discriminant = b * b - 4.0f * a * c;

                if (discriminant < 0) {
                    return rayHit; // No intersection
                }

                // Calculate the nearest intersection point (t)
                float sqrtDiscriminant = sqrt(discriminant);
                float t1 = (-b - sqrtDiscriminant) / (2.0f * a);
                float t2 = (-b + sqrtDiscriminant) / (2.0f * a);

                // Find the closest positive t value
                float t = (t1 > 0) ? t1 : t2;
                if (t < 0) {
                    return rayHit; // Both intersections are behind the ray origin
                }

                // Populate the RayHit structure
                rayHit.isHit = true;
                rayHit.distance = t;
                rayHit.hitPoint = ray.origin + t * ray.direction; // Point of intersection
                rayHit.normalVector = normalize(rayHit.hitPoint - sphere.center); // Normal at the intersection

                return rayHit;
            }

            RayHit CalculateNearestCollesion(Ray ray){
                RayHit closestHit = (RayHit)0;

                ////Iterate trough all Spheres
                //for(int i = 0 ; i < numSpheres; i++){
                //    float shortestHitLength = 1e20;
                //    RayHit actualHit = HitSphere(ray, sphere);

                //    if(actualHit.isHit && actualHit.distance < shortestHitLength){
                //        shortestHitLength = actualHit.distance;
                //        closestHit == actualHit;
                //    }

                //}
            }

            float4 frag (v2f i) : SV_Target
            {
                float3 viewPointLocal = float3(i.uv - 0.5, 1) * ViewParams;
                float3 viewPoint = mul(CamLocalToWorldMatrix, float4(viewPointLocal, 1));

                Ray ray;
                ray.origin = _WorldSpaceCameraPos;
                ray.direction = normalize(viewPoint - ray.origin);

                Sphere sphere;
                sphere.radius = 1;
                sphere.center = float3(0,0,0);
                return float4(HitSphere(ray, sphere).isHit,0,0,1);
            }

            




            ENDCG
        }
    }
}
