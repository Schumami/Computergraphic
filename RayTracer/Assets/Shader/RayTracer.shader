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
                float4 colour;          // The color of the ray.
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
            int MaxBounces;
            int RaysPerPixel;
            sampler2D PreviousFrame;
            int FrameNumber;

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
                RayHit rayHit = (RayHit)0;

                // Vector from ray origin to sphere center
                float3 oc = ray.origin - sphere.center;

                // Quadratic coefficients
                float a = dot(ray.direction, ray.direction);
                float b = 2 * dot(oc, ray.direction);
                float c = dot(oc, oc) - sphere.radius * sphere.radius;

                // Discriminant
                float discriminant = b * b - 4 * a * c;

                if (discriminant < 0) {
                    return rayHit; // No intersection
                }

                float t = (-b - sqrt(discriminant)) / (2 * a);

                // Populate RayHit
                if(t >= 0){
                    rayHit.isHit = true;
                    rayHit.distance = t;
                    rayHit.hitPoint = ray.origin + ray.direction * t;
                    rayHit.normalVector = normalize(rayHit.hitPoint - sphere.center);
                }
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



            // Function to return next random numbr
			uint NextRandom(inout uint state)
			{
				state = state * 747796405 + 2891336453;
				uint result = ((state >> ((state >> 28) + 4)) ^ state) * 277803737;
				result = (result >> 22) ^ result;
				return result;
			}

            // Function to return random Value
			float RandomValue(inout uint state)
			{
				return NextRandom(state) / 4294967295.0; // 2^32 - 1
			}

            // Box-Muller method to generate normally distributed random numbers
			float RandomValueNormalDistribution(inout uint state)
			{
				// Thanks to https://stackoverflow.com/a/6178290
				float theta = 2 * 3.1415926 * RandomValue(state);
				float rho = sqrt(-2 * log(RandomValue(state)));
				return rho * cos(theta);
			}

			// Calculate a random direction
			float3 RandomDirection(inout uint state)
			{
				// Thanks to https://math.stackexchange.com/a/1585996
				float x = RandomValueNormalDistribution(state);
				float y = RandomValueNormalDistribution(state);
				float z = RandomValueNormalDistribution(state);
				return normalize(float3(x, y, z));
			}


            // Function to calculate the new direction of a ray after a bounce
            float3 CalculateNewDirection(float3 incomingRay, float3 normalVector, inout uint rngState){               
                float3 randomDirection = RandomDirection(rngState);

                float3 reflectedRay = randomDirection * sign(dot(normalVector, randomDirection));


                return reflectedRay;
            }



            float4 Trace(Ray ray, inout uint rngState){
                ray.colour = float4(1,1,1,1);                                                       // Set the color of the ray to white at the beginning.
                
                for(int bounces = 0; bounces <= MaxBounces; bounces++){
                    ClosestHit closestHit = CalculateNearestCollision(ray);
                    if(!closestHit.hitInformation.isHit){                                           // Checks if the ray has hit something or not.
                    // Returns a little bit of light for a smooth background lightning
                        return float4(0,0,0,0);
                    }       
                    if(closestHit.hittedSphere.material.emissionStrength > 0){                      // Checks if the object is a light source.
                        float4 lightSourceColour = closestHit.hittedSphere.material.emissionColour; // Calculate the emmision color.
                        
                        float angleStreangth = dot(closestHit.hitInformation.normalVector, -ray.direction);
                        float lightStrenght = closestHit.hittedSphere.material.emissionStrength * angleStreangth;                                                         // Calculate the emmision strenght.
                        
                        
                        
                        return (ray.colour * lightSourceColour) * lightStrenght;                                      // Returns the ray color multiplied by the color and strength of the lightsource.
                    }
                    else{
                        ray.colour *= closestHit.hittedSphere.material.colour;                      // Multiplies the current ray color with the color of the object
                        ray.origin = closestHit.hitInformation.hitPoint;                            // Set new origin of the ray to the hit point of the ray on last object.
                        ray.direction =  CalculateNewDirection(ray.direction, closestHit.hitInformation.normalVector, rngState);                                    // Set the new direction in regard to th              
                    
                    }
                }
                return 0;
                //return ray.colour * float4(0.001,0.001,0.001,0.001);                                                           // Returns nothing, because the bounce limit is reached.
            }



            // The shader that represents the ray tracer.
            // Returns the color value of each corresponding pixel.
            // Generates for each pixel a number of rays.
            float4 frag (v2f i) : SV_Target
            {
                // Create seed for random number generator
				uint2 numPixels = _ScreenParams.xy;
				uint2 pixelCoord = i.uv * numPixels;
				uint pixelIndex = pixelCoord.y * numPixels.x + pixelCoord.x;
				uint rngState = pixelIndex * 475689 * FrameNumber;
                
                float4 lastPixel = tex2D(PreviousFrame, i.uv);


                float3 viewPointLocal = float3(i.uv - 0.5, 1) * ViewParams;
                float3 viewPoint = mul(CamLocalToWorldMatrix, float4(viewPointLocal, 1));

                Ray ray;
                ray.origin = _WorldSpaceCameraPos;
                ray.direction = normalize(viewPoint - ray.origin);

                float4 pixel = 0;
                for ( int rayNr = 0; rayNr < RaysPerPixel; rayNr++ ){
                    pixel += Trace(ray, rngState);
                }
                
                return (pixel*10 + lastPixel*90)/100;                 // Calculate the average between frames.
            }
            ENDCG
        }
    }
}
