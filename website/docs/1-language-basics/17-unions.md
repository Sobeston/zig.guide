# Unions

Zig's unions allow you to define types which store one value of many possible
typed fields; only one field may be active at one time.

Bare union types do not have a guaranteed memory layout. Because of this, bare
unions cannot be used to reinterpret memory. Accessing a field in a union which
is not active is detectable illegal behaviour.

<!--fail_test-->

```zig
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.34;
}
```

```
test "simple union"...access of inactive union field
.\tests.zig:342:12: 0x7ff62c89244a in test "simple union" (test.obj)
    result.float = 12.34;
           ^
```

Tagged unions are unions which use an enum to detect which field is active. Here
we make use of payload capturing again, to switch on the tag type of a union
while also capturing the value it contains. Here we use a _pointer capture_;
captured values are immutable, but with the `|*value|` syntax, we can capture a
pointer to the values instead of the values themselves. This allows us to use
dereferencing to mutate the original value.

```zig
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
```

The tag type of a tagged union can also be inferred. This is equivalent to the
Tagged type above.

<!--no_test-->

```zig
const Tagged = union(enum) { a: u8, b: f32, c: bool };
```

`void` member types can have their type omitted from the syntax. Here, none is
of type `void`.

```zig
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
```
