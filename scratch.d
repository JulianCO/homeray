import std.stdio;
import std.container;

void main() {
    // Example from "Introduction to Algorithms" Cormen et al, p 146
    auto a = make!(std.container.Array!int)([ 4, 1, 3, 2, 16, 9, 10, 14, 8, 7 ]);
    std.container.Array!int b;
    auto h = BinaryHeap!(Array!int)(b);
    foreach(int x ; a)
        h.insert(x);
    // largest element
    assert(h.front == 16);
    // a has the heap property
}
