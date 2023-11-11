# Switch

Zig's `switch` works as both a statement and an expression. The types of all
branches must coerce to the type which is being switched upon. All possible
values must have an associated branch - values cannot be left out. Cases cannot
fall through to other branches.

An example of a switch statement. The else is required to satisfy the
exhaustiveness of this switch.

```zig
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}
```

Here is the former, but as a switch expression.

```zig
test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}
```
