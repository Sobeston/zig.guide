# Formatting specifiers

[`std.fmt`](https://ziglang.org/documentation/master/std/#std;fmt) provides
options for formatting various data types.

`std.fmt.fmtSliceHexLower` and `std.fmt.fmtSliceHexUpper` provide hex formatting
for strings as well as `{x}` and `{X}` for ints.

```zig
const bufPrint = std.fmt.bufPrint;

test "hex" {
    var b: [8]u8 = undefined;

    _ = try bufPrint(&b, "{X}", .{4294967294});
    try expect(eql(u8, &b, "FFFFFFFE"));

    _ = try bufPrint(&b, "{x}", .{4294967294});
    try expect(eql(u8, &b, "fffffffe"));

    _ = try bufPrint(&b, "{}", .{std.fmt.fmtSliceHexLower("Zig!")});
    try expect(eql(u8, &b, "5a696721"));
}
```

`{d}` performs decimal formatting for numeric types.

```zig
test "decimal float" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d}", .{16.5}),
        "16.5",
    ));
}
```

`{c}` formats a byte into an ascii character.

```zig
test "ascii fmt" {
    var b: [1]u8 = undefined;
    _ = try bufPrint(&b, "{c}", .{66});
    try expect(eql(u8, &b, "B"));
}
```

`std.fmt.fmtIntSizeDec` and `std.fmt.fmtIntSizeBin` output memory sizes in
metric (1000) and power-of-two (1024) based notation.

```zig
test "B Bi" {
    var b: [32]u8 = undefined;

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1)}), "1B"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1)}), "1B"));

    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024)}), "1.024kB"));
    try expect(eql(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024)}), "1KiB"));

    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024 * 1024 * 1024)}),
        "1.073741824GB",
    ));
    try expect(eql(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024 * 1024 * 1024)}),
        "1GiB",
    ));
}
```

`{b}` and `{o}` output integers in binary and octal format.

```zig
test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{b}", .{254}),
        "11111110",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{o}", .{254}),
        "376",
    ));
}
```

`{*}` performs pointer formatting, printing the address rather than the value.

```zig
test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{*}", .{@as(*u8, @ptrFromInt(0xDEADBEEF))}),
        "u8@deadbeef",
    ));
}
```

`{e}` outputs floats in scientific notation.

```zig
test "scientific" {
    var b: [16]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    ));
}
```

`{s}` outputs strings.

```zig
test "string fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    try expect(eql(
        u8,
        try bufPrint(&b, "{s}", .{hello}),
        "hello!",
    ));
}
```

This list is non-exhaustive.
