# Comptime

Blocks of code may be forcibly executed at compile time using the
[`comptime`](https://ziglang.org/documentation/master/#comptime) keyword. In
this example, the variables x and y are equivalent.

```zig
test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}
```

Integer literals are of the type `comptime_int`. These are special in that they
have no size (they cannot be used at runtime!), and they have arbitrary
precision. `comptime_int` values coerce to any integer type that can hold them.
They also coerce to floats. Character literals are of this type.

```zig
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}
```

`comptime_float` is also available, which internally is an `f128`. These cannot
be coerced to integers, even if they hold an integer value.

Types in Zig are values of the type `type`. These are available at compile time.
We have previously encountered them by checking
[`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf) and comparing with
other types, but we can do more.

```zig
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}
```

Function parameters in Zig can be tagged as being
[`comptime`](https://ziglang.org/documentation/master/#comptime). This means
that the value passed to that function parameter must be known at compile time.
Let's make a function that returns a type. Notice how this function is
PascalCase, as it returns a type.

```zig
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}
```

We can reflect upon types using the built-in
[`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo), which takes
in a `type` and returns a tagged union. This tagged union type can be found in
[`std.builtin.Type`](https://ziglang.org/documentation/master/std/#std.builtin.Type)
(info on how to make use of imports and std later).

```zig
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}
```

We can use the [`@Type`](https://ziglang.org/documentation/master/#Type)
function to create a type from a
[`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo).
[`@Type`](https://ziglang.org/documentation/master/#Type) is implemented for
most types but is notably unimplemented for enums, unions, functions, and
structs.

Here anonymous struct syntax is used with `.{}`, because the `T` in `T{}` can be
inferred. Anonymous structs will be covered in detail later. In this example we
will get a compile error if the `Int` tag isn't set.

```zig
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}
```

Returning a struct type is how you make generic data structures in Zig. The
usage of [`@This`](https://ziglang.org/documentation/master/#This) is required
here, which gets the type of the innermost struct, union, or enum. Here
[`std.mem.eql`](https://ziglang.org/documentation/master/std/#std;mem.eql) is
also used which compares two slices.

```zig
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}
```

The types of function parameters can also be inferred by using `anytype` in
place of a type. [`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf)
can then be used on the parameter.

```zig
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}
```

Comptime also introduces the operators `++` and `**` for concatenating and
repeating arrays and slices. These operators do not work at runtime.

```zig
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}
```
