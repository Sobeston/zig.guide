# Inline Loops

`inline` loops are unrolled, and allow some things to happen that only work at
compile time. Here we use a
[`for`](https://ziglang.org/documentation/master/#inline-for), but a
[`while`](https://ziglang.org/documentation/master/#inline-while) works
similarly.

```zig
test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}
```

Using these for performance reasons is inadvisable unless you've tested that
explicitly unrolling is faster; the compiler tends to make better decisions here
than you.
