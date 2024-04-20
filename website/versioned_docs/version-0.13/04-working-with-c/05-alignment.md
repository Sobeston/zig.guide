# Alignment

For circuitry reasons, CPUs access primitive values at specific multiples in
memory. This could mean, for example, that the address of an `f32` value must be
a multiple of 4, meaning `f32` has an alignment of 4. This so-called "natural
alignment" of primitive data types depends on CPU architecture. All alignments
are powers of 2.

Data of a larger alignment also has the alignment of every smaller alignment;
for example, a value which has an alignment of 16 also has an alignment of 8, 4,
2 and 1.

We can make specially aligned data by using the `align(x)` property. Here we are
making data with a greater alignment.

```zig
const a1: u8 align(8) = 100;
const a2 align(8) = @as(u8, 100);
```

And making data with a lesser alignment. Note: Creating data of a lesser
alignment isn't particularly useful.

```zig
const b1: u64 align(1) = 100;
const b2 align(1) = @as(u64, 100);
```

Like `const`, `align` is also a property of pointers.

```zig
test "aligned pointers" {
    const a: u32 align(8) = 5;
    try expect(@TypeOf(&a) == *align(8) const u32);
}
```

Let's make use of a function expecting an aligned pointer.

```zig
fn total(a: *align(64) const [64]u8) u32 {
    var sum: u32 = 0;
    for (a) |elem| sum += elem;
    return sum;
}

test "passing aligned data" {
    const x align(64) = [_]u8{10} ** 64;
    try expect(total(&x) == 640);
}
```
