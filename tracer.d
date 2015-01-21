import std.math;
import std.algorithm;
import std.conv;
import std.random;
import types;
import myheap;

struct SamplingTask {
    float weight;
    Vector!float origin;
    Vector!float direction;
    float n; // Diffraction index
}

struct SamplingResult {
    Vector!float color;
    float colorWeight;
}


class Scene {
    private Vector!float camera;
    private Vector!float front;
    private Vector!float right;
    private Vector!float up;

    private float focalPlane; // Actually, the distance to it
    private float lensAperture; // Well, kind of, it's half the projection of the 
                                // Aperture from the focal plane to the screen

    private Vector!float[] lightSources;
    
    private SceneObject[] objects;

    this(Vector!float cameraPosition, Vector!float lookAt, float pixelWidth = 0.005) {
        camera = cameraPosition;
        front = ~(lookAt - cameraPosition);
        right = (~(front^^(Vector!float(0,0,1)))).scale(pixelWidth);
        up = (~(right^^front)).scale(pixelWidth);
        focalPlane = 3.0;
        lensAperture = 0.0;
    }

    void appendObject(SceneObject object) {
        objects ~= object;
    }

    void addLightSource(Vector!float light) {
        lightSources ~= light;
    }

    void setDepthOfField(float distanceToFocalPlane, float aperture) {
        focalPlane = distanceToFocalPlane;
        lensAperture = aperture;
    }

    Vector!float samplePixel(int x, int y) {
        Vector!float focusPoint = camera + (front + right.scale(x) + up.scale(y)).scale(focalPlane);
        auto color = Vector!float(0,0,0);
        Vector!float offset;
        Vector!float origin;
        Vector!float rayDirection;
        for(int i = 0; i < 30; i++) {
            offset = up.scale(uniform(-lensAperture, lensAperture)) +
                     right.scale(uniform(-lensAperture, lensAperture));
            origin = camera + offset;
            rayDirection = ~(focusPoint - origin);
            color = color + sampleRay(origin, rayDirection);
        }
        return color.scale(1/30.0);
    }
    /* TODO: OK, in case I don't finish: I want to sample first the rays that will
       have the largest impact on the final color of the pixel, so I use a heap to
       keep a handle on the largest coefficient. The function sampleRay is charged 
       with sampling until a satisfactory level of precision is achieved. The function
       sampleSingleRay will follow a ray and return it's contribution to the colour
       (from diffusion and phong) and update the heap to include the reflected and
       refracted rays. */

    Vector!float sampleRay(Vector!float origin, Vector!float direction) {
        auto tasks = MyHeap!(SamplingTask, "a.weight < b.weight")();

        float totalWeight = 0.0;
        Vector!float totalColor = Vector!float(0,0,0);
        SamplingTask initialRay = SamplingTask(1.0, origin, direction, 1.0);
        tasks.insert(initialRay);

        SamplingTask currentTask;
        SamplingResult res;

        while(0.99 - totalWeight > EPSILON) {
            currentTask = tasks.takeFront();
            res = sampleSingleRay(currentTask, tasks);
            totalWeight += res.colorWeight;
            totalColor = res.color + totalColor;
        }

        return totalColor.scale(1.00/totalWeight);
    }

    private SamplingResult sampleSingleRay(SamplingTask currentTask, 
            MyHeap!(SamplingTask, "a.weight < b.weight") tasks ) {
        Intersection[] intersections;
        Intersection current;
        foreach(SceneObject object; objects) {
            current = object.trace(currentTask.origin, currentTask.direction);
            if(current.distance != -1)
                intersections ~= current;
        }

        if(intersections.length == 0) 
            return SamplingResult(Vector!float(0,0,0).scale(currentTask.weight),
                                  currentTask.weight);

        auto intersection = (minPos!("a.distance < b.distance")(intersections))[0];

        // the closest interception point
        Vector!float pos = currentTask.origin + currentTask.direction.scale(intersection.distance);
        Vector!float reflectedDirection = currentTask.direction - 
            intersection.normal.scale(2*intersection.normal.dot(currentTask.direction));

        // Adding the reflected rays to be traced in the list of tasks
        if(intersection.reflectionCoefficient > EPSILON) {
            SamplingTask reflectedRay = SamplingTask(
                                            currentTask.weight*intersection.reflectionCoefficient,
                                            pos, 
                                            reflectedDirection,
                                            currentTask.n);
            tasks.insert(reflectedRay);
        }

        /* We want to color the point depending on how
           directly it is hit by the light, this is indicated by
           the dot product of the normal and the direction to each 
           light source */
        float lightIntensity = 0;
        bool inShadow;
        Vector!float l;
        foreach(Vector!float light; lightSources) {
            inShadow = false;
            // find the direction from the intersection to the light
            l = ~(light - pos);
            //check if it lies in the shadow of another object
            foreach(SceneObject object; objects) {
                // Why 5 times epsilon? Lower values were creating problems
                // where an object would appear to be under its own shadow,
                // because of the imprecision of floating point arithmetic
                if(object.trace(pos, l).distance > 5*EPSILON)  {
                    inShadow = true;
                }
            }
            
            if(!inShadow) {
                lightIntensity += intersection.diffusionCoefficient*max(0, l.dot(intersection.normal));
                if(intersection.phongCoefficient > EPSILON) {
                    lightIntensity += intersection.phongCoefficient*pow(max(0,l.dot(reflectedDirection)), intersection.shininess);
                }
            }
        }
        // We divide the intensity by the number of sources to ensure
        // it is smaller or equal to 1
        lightIntensity = lightIntensity/lightSources.length;
        auto finalColor = intersection.color.scale(0.9*lightIntensity + 
                        0.1*(intersection.diffusionCoefficient + intersection.phongCoefficient));
        auto finalWeight = currentTask.weight*(intersection.diffusionCoefficient + intersection.phongCoefficient);
        
        return SamplingResult(finalColor.scale(currentTask.weight), finalWeight);
    }
}
