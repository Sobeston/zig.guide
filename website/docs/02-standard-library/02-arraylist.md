# Arraylist

The
[`std.ArrayList`](https://ziglang.org/documentation/master/std/#A;std:ArrayList)
is commonly used throughout Zig, and serves as a buffer which can change in
size. `std.ArrayList(T)` is similar to C++'s `std::vector<T>` and Rust's
`Vec<T>`. The `deinit()` method frees all of the ArrayList's memory. The memory
can be read from and written to via its slice field - `.items`.

Here we will introduce the usage of the testing allocator. This is a special
allocator that only works in tests and can detect memory leaks. In your code,
use whatever allocator is appropriate.

```zig
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    try expect(eql(u8, list.items, "Hello World!"));
}
```
