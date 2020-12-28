---
title: "Chapter 2 - Standard Patterns"
weight: 3
date: 2020-12-05 16:00:00
description: "Chapter 2 - This section of the tutorial will cover the zig programming language's standard library in detail."
---

Automatically generated standard library documentation can be found [here](https://ziglang.org/documentation/master/std/). Installing [ZLS](https://github.com/zigtools/zls/) may also help you explore the standard library, which provides completions for it.

# Allocators

The zig standard library provides a pattern for allocating memory, which allows the programmer to choose exactly how memory allocations are done within the standard library - no allocations happen behind your back in the standard library.

The most basic allocator is `std.heap.page_allocator`. Whenever this allocator makes an allocation it will ask your OS for an entire page of memory, which may be multiple kilobytes of memory even if only a single byte is used. As asking the OS for memory requires a system call this is also extremely inefficient for speed.

Here, we allocate 100 bytes as a `[]u8`. Notice how defer is used in conjunction with a free - this is a common pattern for memory management in zig.

```zig
const std = @import("std");

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    expect(memory.len == 100);
    expect(@TypeOf(memory) == []u8);
}
```

The `std.heap.FixedBufferAllocator` is an allocator that allocates memory into a fixed buffer, and does not make any heap allocations. This is useful when heap usage is not wanted, for example when writing a kernel. It may also be considered for performance reasons. It will give you the error `OutOfMemory` if it has run out of bytes.

```zig
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    expect(memory.len == 100);
    expect(@TypeOf(memory) == []u8);
}
```

`std.heap.ArenaAllocator` takes in a child allocator, and allows you to allocate many times and only free once. Here, `.deinit()` is called on the arena which frees all memory. Using `allocator.free` in this example would be a no-op (i.e. does nothing).

```zig
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const m1 = try allocator.alloc(u8, 1);
    const m2 = try allocator.alloc(u8, 10);
    const m3 = try allocator.alloc(u8, 100);
}
```

`alloc` and `free` are used for slices. For single items, consider using `create` and `destroy`.

```zig
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}
```

The Zig standard library also has a general purpose allocator. This is a safe allocator which can prevent double-free, use-after-free and can detect leaks. Safety checks and thread safety can be turned off via its configuration struct (left empty below). Zig's GPA is designed for safety over performance, but may still be many times faster than page_allocator.

```zig
test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false); //fail test
    } 
    const bytes = try gpa.allocator.alloc(u8, 100);
    defer gpa.allocator.free(bytes);
}
```

For high performance (but very few safety features!), `std.heap.c_allocator` may be considered. This however has the disadvantage of requiring linking Libc, which can be done with `-lc`.

Benjamin Feng's talk [*What's a Memory Allocator Anyway?*](https://www.youtube.com/watch?v=vHWiDx_l4V0) goes into more detail on this topic, and covers the implementation of allocators.

# Arraylist

The `std.ArrayList` is commonly used throughout Zig, and serves as a buffer which can change in size. `std.ArrayList(T)` is similar to C++'s `std::vector<T>` and Rust's `Vec<T>`. The `deinit()` method frees all of the ArrayList's memory. The memory can be read from and written to via its slice field - `.items`.

Here we will introduce the usage of the testing allocator. This is a special allocator that only works in tests, and can detect memory leaks. In your code, use whatever allocator is appropriate.

```zig
const std = @import("std");
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    expect(eql(u8, list.items, "Hello World!"));
}
```

# Filesystem

Let's create and open a file in our current working directory, write to it, and then read from it. Here we have to use `.seekTo` in order to go back to the start of the file before reading what we have written.

```zig
test "createFile, write, seekTo, read" {
    const file = try std.fs.cwd().createFile(
        "junk_file.txt",
        .{ .read = true },
    );
    defer file.close();

    const bytes_written = try file.writeAll("Hello File!");

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);
    
    expect(eql(u8, buffer[0..bytes_read], "Hello File!"));
}
```

The functions `std.fs.openFileAbsolute` and similar absolute functions exist, but we will not test them here.

<!-- TODO: directory walking -->

# Readers and Writers

`std.io.Writer` and `std.io.Reader` provide standard ways of making use of IO. `std.ArrayList(u8)` has a `writer` method which gives us a writer. Let's use it.

```zig
test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    expect(bytes_written == 12);
    expect(eql(u8, list.items, "Hello World!"));
}
```

Here we will use a reader to copy the file's contents into an allocated buffer. The second argument of `readAllAlloc` is the maximum size that it may allocate; if the file is larger than this, it will return `error.StreamTooLong`.

```zig
test "io reader usage" {
    const message = "Hello File!";

    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();

    try file.writeAll(message);
    try file.seekTo(0);

    const contents = try file.reader().readAllAlloc(
        test_allocator,
        message.len,
    );
    defer test_allocator.free(contents);

    expect(eql(u8, contents, message));
}
```

An `std.io.Writer` type consists of a context type, error set, and a write function. The write function must take in the context type and a byte slice. The write function must also return an error union of the Writer type's error set and the amount of bytes written. Let's create a type that implements a writer.

```zig
// Don't create a type like this! Use an
// arraylist with a fixed buffer allocator
const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    const Writer = std.io.Writer(
        *MyByteList,
        error{EndOfBuffer},
        appendWrite,
    );

    fn appendWrite(
        self: *MyByteList,
        data: []const u8,
    ) error{EndOfBuffer}!usize {
        if (self.items.len + data.len > self.data.len) {
            return error.EndOfBuffer;
        }
        std.mem.copy(
            u8,
            self.data[self.items.len..],
            data,
        );
        self.items = self.data[0..self.items.len + data.len];
        return data.len;
    }

    fn writer(self: *MyByteList) Writer {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};
    _ = try bytes.writer().write("Hello");
    _ = try bytes.writer().write(" Writer!");
    expect(eql(u8, bytes.items, "Hello Writer!"));
}
```

# Formatting

`std.fmt` provides ways to format data to and from strings. 

A basic example of creating a formatted string. The format string must be compile time known.

```zig
test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    expect(eql(u8, string, "9 + 10 = 19"));
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
    expect(eql(u8, list.items, "9 + 10 = 19"));
}
```

Take a moment to appreciate that you now know from top to bottom how printing hello world works. `std.debug.print` works the same, except it writes to stderr and is protected by a mutex.

```zig
test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {}!\n",
        .{"World"},
    );
}
```

Let's create a type with custom formatting by giving it a `format` function. This function must be marked as `pub` so that std.fmt can access it (more on packages later).

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
        try writer.print("{} ({}-", .{
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
        "{}",
        .{john},
    );
    defer test_allocator.free(john_string);

    expect(eql(
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
        "{}",
        .{claude},
    );
    defer test_allocator.free(claude_string);

    expect(eql(
        u8,
        claude_string,
        "Claude Shannon (1916-2001)",
    ));
}
```

# JSON

Let's parse a json string into a struct type, using the streaming parser.

```zig
const Place = struct { lat: f32, long: f32 };

test "json parse" {
    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422 }
    );
    const x = try std.json.parse(Place, &stream, .{});

    expect(x.lat == 40.684540);
    expect(x.long == -74.401422);
}
```

And using stringify to turn arbitrary data into a string.

```zig
test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(&fba.allocator);
    try std.json.stringify(x, .{}, string.writer());

    expect(eql(
        u8,
        string.items,
        \\{"lat":5.19976654e+01,"long":-7.40687012e-01}
    ));
}
```

The json parser requires an allocator for javascript's string, array, and map types. This memory may be freed using `std.json.parseFree`.

```zig
test "json parse with strings" {
    var stream = std.json.TokenStream.init(
        \\{ "name": "Joe", "age": 25 }
    );

    const User = struct { name: []u8, age: u16 };

    const x = try std.json.parse(
        User,
        &stream,
        .{ .allocator = test_allocator },
    );

    defer std.json.parseFree(
        User,
        x,
        .{ .allocator = test_allocator },
    );

    expect(eql(u8, x.name, "Joe"));
    expect(x.age == 25);
}
```

# Random Numbers

Here we create a new prng using a 64 bit random seed. a, b, c, and are given random values via this prng. The expressions giving c and d values are equivalent. `DefaultPrng` is `Xoroshiro128`; there are other prngs available in std.rand.

```zig
test "random numbers" {
    var seed: u64 = undefined;
    try std.os.getRandom(std.mem.asBytes(&seed));
    var rand = std.rand.DefaultPrng.init(seed);

    const a = rand.random.float(f32);
    const b = rand.random.boolean();
    const c = rand.random.int(u8);
    const d = rand.random.intRangeAtMost(u8, 0, 255);
}
```

# Threads

While zig provides more advanced ways or writing concurrent and parallel code, `std.Thread` is available for making use of OS threads. Let's make use of an OS thread.

```zig
fn ticker(step: u8) void {
    while(true) {
        std.time.sleep(1 * std.time.ns_per_s);
        tick += @as(isize, step);
    }
}

var tick: isize = 0;

test "threading" {
    var thread = try std.Thread.spawn(@as(u8, 1), ticker);
    expect(tick == 0);
    std.time.sleep(3 * std.time.ns_per_s / 2);
    expect(tick == 1);
}
```

Threads, however, aren't particularly useful without strategies for thread safety.

# Hash Maps

The standard library provides `std.AutoHashMap`, which lets you easily create a hash map type from a key type and a value type. These must be initiated with an allocator.

Let's put some values in a hash map.

```zig
test "hashing" {
    const Point = struct { x: i32, y: i32 };

    var map = std.AutoHashMap(u32, Point).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(1525, .{ .x = 1, .y = -4 });
    try map.put(1550, .{ .x = 2, .y = -3 });
    try map.put(1575, .{ .x = 3, .y = -2 });
    try map.put(1600, .{ .x = 4, .y = -1 });

    expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        sum.x += entry.value.x;
        sum.y += entry.value.y;
    }

    expect(sum.x == 10);
    expect(sum.y == -10);
}
```

`.fetchPut` puts a value in the hash map, returning a value if there was previously a value for that key.

```zig
test "fetchPut" {
    var map = std.AutoHashMap(u8, f32).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put(255, 10);
    const old = try map.fetchPut(255, 100);

    expect(old.?.value == 10);
    expect(map.get(255).? == 100);
}
```

`std.StringHashMap` is also provided for when you need strings as keys.

```zig
test "string hashmap" {
    var map = std.StringHashMap(enum { cool, uncool }).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    expect(map.get("me").? == .cool);
    expect(map.get("loris").? == .uncool);
}
```

`std.StringHashMap` and `std.AutoHashMap` are just wrappers for `std.HashMap`. If these two do not fulfil your needs, using `std.HashMap` directly gives you much more control.

If having your elements backed by an array is wanted behaviour, try `std.ArrayHashMap` and its wrapper `std.AutoArrayHashMap`.

# Stacks

`std.ArrayList` provides the methods necessary to use it as a stack. Here's an example of creating a list of matched brackets.

```zig
test "stack" {
    const string = "(()())";
    var stack = std.ArrayList(usize).init(
        test_allocator,
    );
    defer stack.deinit();

    const Pair = struct { open: usize, close: usize };
    var pairs = std.ArrayList(Pair).init(
        test_allocator,
    );
    defer pairs.deinit();

    for (string) |char, i| {
        if (char == '(') try stack.append(i);
        if (char == ')')
            try pairs.append(.{
                .open = stack.pop(),
                .close = i,
            });
    }

    for (pairs.items) |pair, i| {
        expect(meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable,
        }));
    }
}
```

# Formatting specifiers
`std.fmt` provides options for formatting various data types.

`{X}` and `{x}` provide hex formatting.
```zig
const bufPrint = std.fmt.bufPrint;

test "hex" {
    var b: [8]u8 = undefined;

    _ = try bufPrint(&b, "{X}", .{4294967294});
    expect(eql(u8, &b, "FFFFFFFE"));

    _ = try bufPrint(&b, "{x}", .{4294967294});
    expect(eql(u8, &b, "fffffffe"));

    _ = try bufPrint(&b, "{x}", .{"zig!"});
    expect(eql(u8, &b, "7a696721"));
}
```

`{d}` performs decimal formatting for numeric types.

```zig
test "decimal float" {
    var b: [4]u8 = undefined;
    expect(eql(
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
    expect(eql(u8, &b, "B"));
}
```

`{B}` and `{Bi}` output memory sizes in metric (1000) and power-of-two (1024) based notation.

```zig
test "B Bi" {
    var b: [32]u8 = undefined;

    expect(eql(u8, try bufPrint(&b, "{B}", .{1}), "1B"));
    expect(eql(u8, try bufPrint(&b, "{Bi}", .{1}), "1B"));

    expect(eql(u8, try bufPrint(&b, "{B}", .{1024}), "1.024kB"));
    expect(eql(u8, try bufPrint(&b, "{Bi}", .{1024}), "1KiB"));

    expect(eql(
        u8,
        try bufPrint(&b, "{B}", .{1024 * 1024 * 1024}),
        "1.073741824GB",
    ));
    expect(eql(
        u8,
        try bufPrint(&b, "{Bi}", .{1024 * 1024 * 1024}),
        "1GiB",
    ));
}
```

`{b}` and `{o}` output integers in binary and octal format.

```zig
test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    expect(eql(
        u8,
        try bufPrint(&b, "{b}", .{254}),
        "11111110",
    ));

    expect(eql(
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
    expect(eql(
        u8,
        try bufPrint(&b, "{*}", .{@intToPtr(*u8, 0xDEADBEEF)}),
        "u8@deadbeef",
    ));
}
```

`{e}` outputs floats in scientific notation.
```zig
test "scientific" {
    var b: [16]u8 = undefined;

    expect(eql(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    ));
}
```

`{s}` outputs zero terminated strings.
```zig
test "terminated fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    expect(eql(
        u8,
        try bufPrint(&b, "{s}", .{hello}),
        "hello!",
    ));
}
```

# Advanced Formatting

So far we have only covered formatting specifiers. Format strings actually follow this format, where between each pair of square brackets is a parameter you have to replace with something.

`{[position][specifier]:[fill][alignment][width].[precision]}`

| Name      | Meaning                                                                                 |
|-----------|-----------------------------------------------------------------------------------------|
| Position  | The index of the argument that should be inserted                                       |
| Specifier | A type-dependent formatting option                                                      |
| Fill      | A single character used for padding                                                     |
| Alignment | One of three characters '<', '^' or '>'; these are for left, middle and right alignment |
| Width     | The total width of the field (characters)                                               |
| Precision | How many decimals a formatted number should have                                        |


Position usage.
```zig
test "position" {
    var b: [3]u8 = undefined;
    expect(eql(
        u8,
        try bufPrint(&b, "{0}{0}{1}", .{"a", "b"}),
        "aab",
    ));
}
```

Fill, alignment and width being used.
```zig
test "fill, alignment, width" {
    var b: [5]u8 = undefined;

    expect(eql(
        u8,
        try bufPrint(&b, "{: <5}", .{"hi!"}),
        "hi!  ",
    ));

    expect(eql(
        u8,
        try bufPrint(&b, "{:_^5}", .{"hi!"}),
        "_hi!_",
    ));

    expect(eql(
        u8,
        try bufPrint(&b, "{:!>4}", .{"hi!"}),
        "!hi!",
    ));
}
```

Using a specifier with precision.
```zig
test "precision" {
    var b: [4]u8 = undefined;
    expect(eql(
        u8,
        try bufPrint(&b, "{d:.2}", .{3.14159}),
        "3.14",
    ));
}
```

# End of Chapter 2

This chapter is incomplete. In the future it will contain things such as:

- Arbitrary Precision Maths
- Linked Lists
- Crypto
- Queues
- Mutexes
- Atomics
- Searching
- Sorting
- Logging

Feedback and PRs are welcome.
