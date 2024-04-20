# Optionals

Optionals use the syntax `?T` and are used to store the data
[`null`](https://ziglang.org/documentation/master/#null), or a value of type
`T`.

```zig
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}
```

Optionals support the `orelse` expression, which acts when the optional is
[`null`](https://ziglang.org/documentation/master/#null). This unwraps the
optional to its child type.

```zig
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}
```

`.?` is a shorthand for `orelse unreachable`. This is used for when you know it
is impossible for an optional value to be null, and using this to unwrap a
[`null`](https://ziglang.org/documentation/master/#null) value is detectable
illegal behaviour.

```zig
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}
```

Both `if` expressions and `while` loops support taking optional values as conditions,
allowing you to "capture" the inner non-null value.

Here we use an `if` optional payload capture; a and b are equivalent here.
`if (b) |value|` captures the value of `b` (in the cases where `b` is not null),
and makes it available as `value`. As in the union example, the captured value
is immutable, but we can still use a pointer capture to modify the value stored
in `b`.

```zig
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}
```

And with `while`:

```zig
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}
```

Optional pointer and optional slice types do not take up any extra memory
compared to non-optional ones. This is because internally they use the 0 value
of the pointer for `null`.

This is how null pointers in Zig work - they must be unwrapped to a non-optional
before dereferencing, which stops null pointer dereferences from happening
accidentally.
