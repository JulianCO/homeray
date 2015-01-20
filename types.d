import std.conv;
import std.math;
immutable float EPSILON = 0.000001;

bool compareFloat(float a, float b, float epsilon = EPSILON) {
    return abs(a - b) < epsilon;
}

// Vector class with common vector operations
struct Vector(T) {
    /// Cartesian coordenates
    T x, y, z;
    
    /// Constructor from the three cartesian coordenates
    this(T a, T b, T c) {
        x = a; y = b; z = c;
    }

    string show() {
        return "<" ~ text(x) ~ ", " ~ text(y) ~ ", " ~ text(z) ~ ">";
    }

    /// Scalar product
    Vector!(T) scale(T a) {
        return Vector(a*x, a*y, a*z);
    }

    /// Vector dot product
    T dot(Vector!(T) b) {
        return x*b.x + y*b.y + z*b.z;
    }

    /// Vector sum, substration and cross product
    Vector!(T) opBinary(string op)(Vector!(T) rhs) {
        static if(op == "+")
            return Vector(x + rhs.x, y + rhs.y, z + rhs.z);
        else static if(op == "-")
            return Vector(x - rhs.x, y - rhs.y, z - rhs.z);
        else static if(op == "^^") // Cross product
            return Vector(y*rhs.z - z*rhs.y, z*rhs.x - x*rhs.z, x*rhs.y - y*rhs.x);
        else static assert(0, "Operator " ~ op ~ " not implemented");
    }

    /// Vector negation and normalization
    Vector!(T) opUnary(string op)() {
        static if(op == "-") // Additive inverse
            return Vector(-x, -y, -z);
        else static if(op == "~")
            return this.scale(1/sqrt(this.dot(this)));
        else static assert(0, "Operator " ~ op ~ " not implemented");
    }
}

unittest {
    auto a = Vector!float(2, 2, 0);
    auto b = Vector!float(-0.5, 4, -3);
    auto zero = Vector!float(0, 0, 0);
    assert(compareFloat((~b).dot(~b), 1.0));
    auto c = (a^^b) + zero - Vector!float(-6, 6, 9);
    assert(compareFloat(c.dot(c), 0));
}


struct Intersection {
    this(float t, Vector!float n, Vector!float co, float d = 1.0, float r = 0.0, 
            float p = 0.0, float ps = 1.0, float tr = 0.0, float n2_ = 1.0) {
        distance = t;
        normal = n;
        diffusionCoefficient = d;
        reflectionCoefficient = r;
        phongCoefficient = p;
        shininess = ps;
        transmittanceCoefficient = tr;
        n2 = n2_;
        color = co;
    }

    float distance; // distance is set to -1 to signal no intersection
    Vector!float normal;
    float diffusionCoefficient;
    float reflectionCoefficient;
    float phongCoefficient;
    float shininess;
    float transmittanceCoefficient;
    float n2; //To calculate the angle of diffraction, of course
    Vector!float color;
}

immutable NO_INTERSECTION = Intersection(-1, Vector!float(1,0,0), Vector!float(0,0,0));

interface SceneObject {
    Intersection trace(Vector!float origin, Vector!float direction);
}

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

