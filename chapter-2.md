---
title: "Chapter 2 - Standard Patterns"
weight: 3
date: 2020-07-06 17:38:10
description: "Chapter 2 - This section of the tutorial will cover the zig programming language's standard library in detail."
---

Standard library documentation can be found [here](https://ziglang.org/documentation/master/std/). Note: as of writing, this documentation is slightly outdated. Installing [ZLS](https://github.com/zigtools/zls/) may help you explore the standard library, whose autocompletions for the standard library will keep up to date.

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

The Zig standard library does not yet have a general-purpose allocator. For a general-purpose allocator consider `std.heap.c_allocator`, which is fast but requires linking libc. Libc can be linked to by adding `-lc`, eg: `zig build-exe main.zig -lc`. Libc will be covered in detail in later chapters.

# Arraylist

The `std.ArrayList` is commonly used throughout Zig, and serves as a buffer which can change in size. `std.ArrayList(T)` is similar to C++'s `std::vector<T>` and Rust's `Vec<T>`. The `deinit()` method frees all of the ArrayList's memory. The memory can be read from and written to via its slice field - `.items`.

```zig
const eql = std.mem.eql;
const heap = std.heap;
const ArrayList = std.ArrayList;

test "arraylist" {
    var list = ArrayList(u8).init(heap.page_allocator);
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
    var list = ArrayList(u8).init(heap.page_allocator);
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    expect(bytes_written == 12);
    expect(eql(u8, list.items, "Hello World!"));
}
```

Here we will use a reader to copy the file's contents into an arraylist.

```zig
test "io reader usage" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();

    _ = try file.writeAll("Hello File!");
    try file.seekTo(0);

    var list = ArrayList(u8).init(heap.page_allocator);
    try file.reader().readAllArrayList(&list, 16 * 1024);

    expect(eql(u8, list.items, "Hello File!"));
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
        heap.page_allocator,
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    defer heap.page_allocator.free(string);

    expect(eql(u8, string, "9 + 10 = 19"));
}
```

Writers conveniently have a `print` method, which works similarly.

```zig
test "print" {
    var list = std.ArrayList(u8).init(heap.page_allocator);
    try list.writer().print(
        "{} + {} = {}",
        .{ 9, 10, 19 }
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
        .{"World"}
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
        writer: var,
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

    expect(eql(
        u8,
        try std.fmt.allocPrint(
            heap.page_allocator,
            "{}",
            .{john},
        ),
        "John Carmack (1970-)",
    ));

    const claude = Person{
        .name = "Claude Shannon",
        .birth_year = 1916,
        .death_year = 2001,
    };

    expect(eql(
        u8,
        try std.fmt.allocPrint(
            heap.page_allocator,
            "{}",
            .{claude},
        ),
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

    const User = struct { name: []u8, age: u16};

    const x = try std.json.parse(
        User,
        &stream,
        .{ .allocator = std.heap.page_allocator },
    );

    defer std.json.parseFree(
        User,
        x,
        .{ .allocator = std.heap.page_allocator },
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
    try std.crypto.randomBytes(std.mem.asBytes(&seed));
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

Let's put some values in a hash map. It is worth noting that the order of insertion is retained.

```zig
test "hashing" {
    const Point = struct { x: i32, y: i32 };

    var map = std.AutoHashMap(f32, Point).init(
        heap.page_allocator,
    );

    try map.put(1.525, .{ .x = 1, .y = -4 });
    try map.put(1.550, .{ .x = 2, .y = -3 });
    try map.put(1.575, .{ .x = 3, .y = -2 });
    try map.put(1.600, .{ .x = 4, .y = -1 });

    expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    for (map.items()) |entry| {
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
        heap.page_allocator,
    );

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
        heap.page_allocator,
    );

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    expect(map.get("me").? == .cool);
    expect(map.get("loris").? == .uncool);
}
```

`std.StringHashMap` and `std.AutoHashMap` are just wrappers for `std.HashMap`. If these two do not fulfil your needs, using HashMap directly gives you much more control.

# Stacks

`std.ArrayList` provides the methods necessary to use it as a stack. Here's an example of creating a list of matched brackets.

```zig
test "stack" {  
    const string = "(()())";
    var stack = std.ArrayList(usize).init(
        heap.page_allocator,
    );

    const Pair = struct { open: usize, close: usize};
    var pairs = std.ArrayList(Pair).init(
        heap.page_allocator
    );

    for (string) |char, i| {
        if (char == '(') try stack.append(i);
        if (char == ')') try pairs.append(.{
            .open = stack.pop(),
            .close = i,
        });
    }

    for (pairs.items) |pair, i| {
        expect(meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable          
        }));
    }
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

The next chapter is planned to cover the build system. Feedback and PRs are welcome.