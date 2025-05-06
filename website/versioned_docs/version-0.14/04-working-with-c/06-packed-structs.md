# Packed Structs

By default, all struct fields in Zig are naturally aligned to that of
[`@alignOf(FieldType)`](https://ziglang.org/documentation/master/#alignOf) (the
ABI size), but without a defined layout. Sometimes you may want to have struct
fields with a defined layout that do not conform to your C ABI. `packed` structs
allow you to have extremely precise control of your struct fields, allowing you
to place your fields on a bit-by-bit basis.

Inside packed structs, Zig's integers take their bit-width in space (i.e. a
`u12` has an [`@bitSizeOf`](https://ziglang.org/documentation/master/#bitSizeOf)
of 12, meaning it will take up 12 bits in the packed struct). Bools also take up
1 bit, meaning you can implement bit flags easily.

```zig
const MovementState = packed struct {
    running: bool = false,
    crouching: bool = false,
    jumping: bool = false,
    in_air: bool = false,
};

test "packed struct size" {
    try expect(@sizeOf(MovementState) == 1);
    try expect(@bitSizeOf(MovementState) == 4);
    const state = MovementState{
        .running = true,
        .crouching = true,
        .jumping = true,
        .in_air = true,
    };
    _ = state;
}
```

## Binary Bitwise Expressions

You can perform binary bitwise operations on integers, but not on packed structs.

```zig
test "packed struct binary OR" {
    var state = MovementState{ .jumping = true };

    // Convert to bits and perform the binary operation
    const backing_type = @typeInfo(MovementState).@"struct".backing_integer.?;
    const new_state_bits = @as(backing_type, @bitCast(state)) | @as(backing_type, @bitCast(MovementState{ .running = true }));

    // Convert back to original type
    state = @bitCast(new_state_bits);

    try expect(state == MovementState{ .jumping = true, .running = true });
}
```
