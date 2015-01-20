import std.stdio;
import std.math;
import std.algorithm;
import std.conv;
import std.random;
import myheap;
import types;
import simple_solids;
import pigment;
import tracer;


void main() {
    auto floor = new CheckeredPlane(Vector!float(0,0,0), // Center
            Vector!float(0,0,1), // Plane normal
            Vector!float(128,128,128), // Color of even indexed squares
            Vector!float(50,50,200)); // Color of odd indexed squares

    Sphere[] balls;
    balls ~= new Sphere(Vector!float(0,0,1), 1.0, Vector!float(210,50,30));
    balls ~= new Sphere(Vector!float(2,0,1), 0.7, Vector!float(150,170,60));
    balls ~= new Sphere(Vector!float(-2.3,0,1.3), 1.3, Vector!float(80, 10, 100));
    balls ~= new Sphere(Vector!float(0,2, 1.5), 1.1, Vector!float(150, 150, 150));
    balls ~= new Sphere(Vector!float(0,-2, 0.6), 0.7, Vector!float(25,200,70));

    // setting camera parameters (position, direction to look at and pixel width)
    auto camera = Vector!float(1.0,-4,4.5);
    auto world = new Scene(camera, Vector!float(0,0,2));

    world.appendObject(floor);
    foreach(Sphere ball; balls)
        world.appendObject(ball);
    world.addLightSource(Vector!float(2, 2, 5));
    world.addLightSource(Vector!float(-3, -2, 6));
    world.setDepthOfField(sqrt(camera.dot(camera)), 22.0);

    auto outfile = new File("hello.ppm", "wb");

    Vector!float color;
    ubyte[512*512*3] buffer;

    for(int y = 0; y < 512; y++) {
        for(int x = 0; x < 512; x++) {
            color = world.samplePixel(x - 256, 256 - y);
            buffer[3*(y*512 + x) .. 3*(y*512 + x + 1)] = [cast(ubyte)color.x, cast(ubyte)color.y, cast(ubyte)color.z];
        }
        writeln(y+1, "/512");
    }

    outfile.rawWrite("P6 512 512 255 ");
    outfile.rawWrite(buffer);
}

