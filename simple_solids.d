import std.algorithm;
import std.math;
import types;


class CheckeredPlane : SceneObject {
    Vector!float center;
    Vector!float planeNormal;
    Vector!float colorEven;
    Vector!float colorOdd;

    Vector!float front; // Used to align the checkered pattern
    Vector!float side;


    this(Vector!float c, // Center
            Vector!float pn, //Normal to the plane
            Vector!float ce, // Color of even-indexed squares
            Vector!float co, // Color of odd indexed squares
            Vector!float forward = Vector!float(0,2,1)) {
        center = c;
        planeNormal = pn;
        colorEven = ce;
        colorOdd = co;

        side = ~(forward^^planeNormal);
        front = ~(planeNormal^^side);
    }

    Intersection trace(Vector!float origin, Vector!float direction) {
        if(compareFloat(planeNormal.dot(direction), 0)) 
            return NO_INTERSECTION;
        
        auto t = planeNormal.dot(center - origin)/planeNormal.dot(direction);
        if(t < EPSILON) 
            return NO_INTERSECTION;
        
        auto position = origin + direction.scale(t) - center;
        auto parity = floor(position.dot(front)) + floor(position.dot(side));
        if(parity % 2 == 0) 
            return Intersection(t, planeNormal, colorEven, 0.6, 0.4);
        else 
            return Intersection(t, planeNormal, colorOdd, 0.6, 0.4);
    }
}

class Sphere : SceneObject {
    Vector!float center;
    float radius;
    Vector!float color;

    this(Vector!float c, float r, Vector!float co) {
        center = c;
        radius = r;
        color = co;
    }

    Intersection trace(Vector!float origin, Vector!float direction) {
        /* This is a quadratic equation, which is convenient because
           I know how to solve them */
        float a = direction.dot(direction);
        float b = direction.dot(origin - center) * 2;
        float c = (origin - center).dot(origin - center) - radius*radius;

        if(b*b - 4*a*c < 0) return NO_INTERSECTION;

        /* Yay quadratic equation! */
        float t = min( ((-b) + sqrt(b*b - 4*a*c))/(2*a),
                       ((-b) - sqrt(b*b - 4*a*c))/(2*a));

        if(t < 0) return NO_INTERSECTION;

        Vector!float pos = origin + direction.scale(t);
        return Intersection(t, ~(pos - center), color, 0.5, 0.3, 0.2,15.0);
    }
}
