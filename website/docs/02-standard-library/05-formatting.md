# Formatting

[`std.fmt`](https://ziglang.org/documentation/master/std/#A;std:fmt) provides
ways to format data to and from strings.

A basic example of creating a formatted string. The format string must be
compile time known. The `d` here denotes that we want a decimal number.

```zig
test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{d} + {d} = {d}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    try expect(eql(u8, string, "9 + 10 = 19"));
}
```

Writers conveniently have a `print` method, which works similarly.

```zig
test "print" {
    var list = std.ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.writer().print(
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    try expect(eql(u8, list.items, "9 + 10 = 19"));
}
```

Take a moment to appreciate that you now know from top to bottom how printing
Hello World works.
[`std.debug.print`](https://ziglang.org/documentation/master/std/#A;std:debug.print)
works the same, except it writes to stderr and is protected by a mutex.

```zig
test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {s}!\n",
        .{"World"},
    );
}
```

We have used the `{s}` format specifier up until this point to print strings.
Here, we will use `{any}`, which gives us the default formatting.

```zig
test "array printing" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{any} + {any} = {any}",
        .{
            @as([]const u8, &[_]u8{ 1, 4 }),
            @as([]const u8, &[_]u8{ 2, 5 }),
            @as([]const u8, &[_]u8{ 3, 9 }),
        },
    );
    defer test_allocator.free(string);

    try expect(eql(
        u8,
        string,
        "{ 1, 4 } + { 2, 5 } = { 3, 9 }",
    ));
}
```

Let's create a type with custom formatting by giving it a `format` function.
This function must be marked as `pub` so that std.fmt can access it (more on
packages later). You may notice the usage of `{s}` instead of `{}` - this is the
format specifier for strings (more on format specifiers later). This is used
here as `{}` defaults to array printing over string printing.

```zig
const Person = struct {
    name: []const u8,
    birth_year: i32,
    death_year: ?i32,
    pub fn format(
        self: Person,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        try writer.print("{s} ({}-", .{
            self.name, self.birth_year,
        });

        if (self.death_year) |year| {
            try writer.print("{}", .{year});
        }

        try writer.writeAll(")");
    }
};

test "custom fmt" {
    const john = Person{
        .name = "John Carmack",
        .birth_year = 1970,
        .death_year = null,
    };

    const john_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{john},
    );
    defer test_allocator.free(john_string);

    try expect(eql(
        u8,
        john_string,
        "John Carmack (1970-)",
    ));

    const claude = Person{
        .name = "Claude Shannon",
        .birth_year = 1916,
        .death_year = 2001,
    };

    const claude_string = try std.fmt.allocPrint(
        test_allocator,
        "{s}",
        .{claude},
    );
    defer test_allocator.free(claude_string);

    try expect(eql(
        u8,
        claude_string,
        "Claude Shannon (1916-2001)",
    ));
}
```
