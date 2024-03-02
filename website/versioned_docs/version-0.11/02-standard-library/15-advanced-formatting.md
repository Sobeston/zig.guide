---
pagination_next: build-system/build-modes
---

# Advanced Formatting

So far we have only covered formatting specifiers. Format strings actually
follow this format, where between each pair of square brackets is a parameter
you have to replace with something.

`{[position][specifier]:[fill][alignment][width].[precision]}`

| Name      | Meaning                                                                          |
| --------- | -------------------------------------------------------------------------------- |
| Position  | The index of the argument that should be inserted                                |
| Specifier | A type-dependent formatting option                                               |
| Fill      | A single character used for padding                                              |
| Alignment | One of three characters < ^ or >; these are for left, middle and right alignment |
| Width     | The total width of the field (characters)                                        |
| Precision | How many decimals a formatted number should have                                 |

Position usage.

```zig
test "position" {
    var b: [3]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{0s}{0s}{1s}", .{ "a", "b" }),
        "aab",
    ));
}
```

Fill, alignment and width being used.

```zig
test "fill, alignment, width" {
    var b: [6]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{s: <5}", .{"hi!"}),
        "hi!  ",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:_^6}", .{"hi!"}),
        "_hi!__",
    ));

    try expect(eql(
        u8,
        try bufPrint(&b, "{s:!>4}", .{"hi!"}),
        "!hi!",
    ));
}
```

Using a specifier with precision.

```zig
test "precision" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d:.2}", .{3.14159}),
        "3.14",
    ));
}
```
