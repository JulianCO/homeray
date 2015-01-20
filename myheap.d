import std.stdio;
import std.container;
import std.functional;

struct MyHeap(T, alias less_ = "a < b") {
    private Array!T store;
    alias binaryFun!(less_) less;

    this(T[] elements = []) {
        store = make!(Array!T)(elements);
        if(elements.length > 1)
            this.heapify();
    }

    private size_t left(size_t i) {
        return 2*i + 1;
    }

    private size_t right(size_t i) {
        return 2*i + 2;
    }

    private size_t parent(size_t i) {
        return (i+1)/2 - 1;
    }

    private void swap(size_t a, size_t b) {
        T temp = store[a];
        store[a] = store[b];
        store[b] = temp;
    }

    private void bubbleUp(size_t i) {
        T elem = store[i];
        debug writeln("bubbling up ", i, " of value ", elem);
        while(i != 0 && less(store[parent(i)], elem)) {
            debug writeln("Swapping ", i, " and ", parent(i));
            swap(i, parent(i));
            i = parent(i);
        }
        debug writeln("done bubbling up");
    }

    private void bubbleDown(size_t i) {
        debug writeln("bubbling down ", i, " of value ", store[i]);
        debug writeln("heap has size ", store.length);
        if(left(i) < store.length) {
            debug writeln("\thas a left child");
            if(right(i) < store.length) {
                debug writeln("\t has a right child");
                // The node has two children, we swap it with the
                // largest, if needed
                if(less(store[i], store[left(i)]) &&
                        less(store[right(i)], store[left(i)])) {
                    debug writeln("\t\tLeft child was larger");
                    swap(i, left(i));
                    bubbleDown(left(i));
                }
                else if(less(store[i], store[right(i)])) {
                    debug writeln("\t\tRight child was larger");
                    swap(i, right(i));
                    bubbleDown(right(i));
                }
            }
            else {
                // the node only has the left child
                if(less(store[i], store[left(i)])) {
                    debug writeln("\t\tLeft child was larger");
                    swap(i, left(i));
                    // no need to bubble down anymore 
                    // because we are at the bottom of the heap
                }
            }
        }
        else debug writeln("Should be done bubbling, now");
    }

    void insert(T a) {
        // first we put the element at the end of the heap
        store.insertBack(a);

        // and then we bubble it up
        bubbleUp(store.length - 1);
    }

    T takeFront() {
        T res = store[0];
        store[0] = store.back();
        store.removeBack();
        if(store.length != 0) {
            bubbleDown(0);
        }

        return res;
    }

    void heapify() {
        debug writeln("heapifying");
        size_t i = store.length/2;
        while(i > 0) {
            debug writeln("let's bubble down: ", i);
            bubbleDown(i - 1);
            i--;
        }
        debug writeln("hello, there");
        debug writeln("heapified into: ", store);
    }
}

unittest {
    MyHeap!int h = MyHeap!int([8,45,3,23,4]);
    h.insert(31);
    assert(h.takeFront() == 45);
    h.insert(7);
    assert(h.takeFront() == 31);
    assert(h.takeFront() == 23);
    assert(h.takeFront() == 8);
    assert(h.takeFront() == 7);

    int hi(MyHeap!(float, "abs(a) < abs(b)") a) {
        return 42;
    }
    assert(hi(MyHeap!(float, "abs(a) < abs(b)")()) == 42);
}


