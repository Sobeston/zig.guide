# Floats

Zig's floats are strictly IEEE compliant unless
[`@setFloatMode(.Optimized)`](https://ziglang.org/documentation/master/#setFloatMode)
is used, which is equivalent to GCC's `-ffast-math`. Floats coerce to larger
float types.

```zig
test "float widening" {
    const a: f16 = 0;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}
```

Floats support multiple kinds of literal.

```zig
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70p-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex_float: f64 = 0x103.70P-5;
```

Underscores may also be placed between digits.

```zig
const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678.9ABC_CDEFp-10;
```

Integers and floats may be converted using the built-in functions
[`@floatFromInt`](https://ziglang.org/documentation/0.11.0/#floatFromInt) and
[`@intFromFloat`](https://ziglang.org/documentation/0.11.0/#intFromFloat).
[`@floatFromInt`](https://ziglang.org/documentation/0.11.0/#floatFromInt) is
always safe, whereas
[`@intFromFloat`](https://ziglang.org/documentation/0.11.0/#intFromFloat) is
detectable illegal behaviour if the float value cannot fit in the integer
destination type.

```zig
test "int-float conversion" {
    const a: i32 = 0;
    const b = @as(f32, @floatFromInt(a));
    const c = @as(i32, @intFromFloat(b));
    try expect(c == a);
}
```
