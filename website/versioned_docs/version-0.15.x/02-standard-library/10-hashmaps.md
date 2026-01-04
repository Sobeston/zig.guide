# Hash Maps

The standard library provides
[`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#std.AutoHashMap),
which lets you easily create a hash map type from a key type and a value type.
These must be initiated with an allocator.

Let's put some values in a hash map.

```zig
test "hashing" {
    const Point = struct { x: i32, y: i32 };

    var map: std.AutoHashMap(u32, Point) = .init(test_allocator);
    defer map.deinit();

    try map.put(1525, .{ .x = 1, .y = -4 });
    try map.put(1550, .{ .x = 2, .y = -3 });
    try map.put(1575, .{ .x = 3, .y = -2 });
    try map.put(1600, .{ .x = 4, .y = -1 });

    try expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        sum.x += entry.value_ptr.x;
        sum.y += entry.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
}
```

`.fetchPut` puts a value in the hash map, returning a value if there was
previously a value for that key.

```zig
test "fetchPut" {
    var map: std.AutoHashMap(u8, f32) = .init(test_allocator);
    defer map.deinit();

    try map.put(255, 10);
    const old = try map.fetchPut(255, 100);

    try expect(old.?.value == 10);
    try expect(map.get(255).? == 100);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#std.StringHashMap)
is also provided for when you need strings as keys.

```zig
test "string hashmap" {
    var map: std.StringHashMap(enum { cool, uncool }) = .init(test_allocator);
    defer map.deinit();

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    try expect(map.get("me").? == .cool);
    try expect(map.get("loris").? == .uncool);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#std.StringHashMap)
and
[`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#std.AutoHashMap)
are just wrappers for
[`std.HashMap`](https://ziglang.org/documentation/master/std/#std.HashMap). If
these two do not fulfil your needs, using
[`std.HashMap`](https://ziglang.org/documentation/master/std/#std.HashMap)
directly gives you much more control.

If having your elements backed by an array is wanted behaviour, try
[`std.ArrayHashMap`](https://ziglang.org/documentation/master/std/#std.ArrayHashMap)
and its wrapper
[`std.AutoArrayHashMap`](https://ziglang.org/documentation/master/std/#std.AutoArrayHashMap).
