# Structs

Structs are Zig's most common kind of composite data type, allowing you to
define types that can store a fixed set of named fields. Zig gives no guarantees
about the in-memory order of fields in a struct or its size. Like arrays,
structs are also neatly constructed with `T{}` syntax. Here is an example of
declaring and filling a struct.

```zig
const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
```

Fields may be given defaults:

<!--fail_test-->

```zig
test "missing struct field" {
    const my_vector = Vec3{
        .x = 0,
        .z = 50,
    };
    _ = my_vector;
}
```

```
error: missing field: 'y'
    const my_vector = Vec3{
                        ^
```

Fields may be given defaults:

```zig
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}
```

Like enums, structs may also contain functions and declarations.

Structs have the unique property that when given a pointer to a struct, one
level of dereferencing is done automatically when accessing fields. Notice how,
in this example, self.x and self.y are accessed in the swap function without
needing to dereference the self pointer.

```zig
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
```
