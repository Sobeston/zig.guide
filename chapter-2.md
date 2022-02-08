---
title: "Chapter 2 - Standard Patterns"
weight: 3
date: 2021-02-15 00:05:00
description: "Chapter 2 - This section of the tutorial will cover the Zig programming language's standard library in detail."
---

Automatically generated standard library documentation can be found [here](https://ziglang.org/documentation/master/std/). Installing [ZLS](https://github.com/zigtools/zls/) may also help you explore the standard library, which provides completions for it.

# Allocators

The Zig standard library provides a pattern for allocating memory, which allows the programmer to choose exactly how memory allocations are done within the standard library - no allocations happen behind your back in the standard library.

The most basic allocator is [`std.heap.page_allocator`](https://ziglang.org/documentation/master/std/#std;heap.page_allocator). Whenever this allocator makes an allocation it will ask your OS for entire pages of memory; an allocation of a single byte will likely reserve multiple kibibytes. As asking the OS for memory requires a system call this is also extremely inefficient for speed.

Here, we allocate 100 bytes as a `[]u8`. Notice how defer is used in conjunction with a free - this is a common pattern for memory management in Zig.

```zig
const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

The [`std.heap.FixedBufferAllocator`](https://ziglang.org/documentation/master/std/#std;heap.FixedBufferAllocator) is an allocator that allocates memory into a fixed buffer, and does not make any heap allocations. This is useful when heap usage is not wanted, for example when writing a kernel. It may also be considered for performance reasons. It will give you the error `OutOfMemory` if it has run out of bytes.

```zig
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}
```

[`std.heap.ArenaAllocator`](https://ziglang.org/documentation/master/std/#std;heap.ArenaAllocator) takes in a child allocator, and allows you to allocate many times and only free once. Here, `.deinit()` is called on the arena which frees all memory. Using `allocator.free` in this example would be a no-op (i.e. does nothing).

```zig
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
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
    const allocator = gpa.allocator();
    defer {
        const leaked = gpa.deinit();
        if (leaked) expect(false) catch @panic("TEST FAIL"); //fail test; can't try in defer as defer is executed after we return
    }
    
    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}
```

For high performance (but very few safety features!), [`std.heap.c_allocator`](https://ziglang.org/documentation/master/std/#std;heap.c_allocator) may be considered. This however has the disadvantage of requiring linking Libc, which can be done with `-lc`.

Benjamin Feng's talk [*What's a Memory Allocator Anyway?*](https://www.youtube.com/watch?v=vHWiDx_l4V0) goes into more detail on this topic, and covers the implementation of allocators.

# Arraylist

The [`std.ArrayList`](https://ziglang.org/documentation/master/std/#std;ArrayList) is commonly used throughout Zig, and serves as a buffer which can change in size. `std.ArrayList(T)` is similar to C++'s `std::vector<T>` and Rust's `Vec<T>`. The `deinit()` method frees all of the ArrayList's memory. The memory can be read from and written to via its slice field - `.items`.

Here we will introduce the usage of the testing allocator. This is a special allocator that only works in tests, and can detect memory leaks. In your code, use whatever allocator is appropriate.

```zig
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

    try expect(eql(u8, list.items, "Hello World!"));
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
    _ = bytes_written;

    var buffer: [100]u8 = undefined;
    try file.seekTo(0);
    const bytes_read = try file.readAll(&buffer);

    try expect(eql(u8, buffer[0..bytes_read], "Hello File!"));
}
```

The functions [`std.fs.openFileAbsolute`](https://ziglang.org/documentation/master/std/#std;fs.openFileAbsolute) and similar absolute functions exist, but we will not test them here.

We can get various information about files by using `.stat()` on them. `Stat` also contains fields for .inode and .mode, but they are not tested here as they rely on the current OS' types.

```zig
test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .File);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}
```

We can make directories and iterate over their contents. Here we will use an iterator (discussed later). This directory (and its contents) will be deleted after this test finishes.

```zig
test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const dir = try std.fs.cwd().openDir(
        "test-tmp",
        .{ .iterate = true },
    );
    defer {
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try dir.createFile("x", .{});
    _ = try dir.createFile("y", .{});
    _ = try dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count == 3);
}
```

# Readers and Writers

[`std.io.Writer`](https://ziglang.org/documentation/master/std/#std;io.Writer) and [`std.io.Reader`](https://ziglang.org/documentation/master/std/#std;io.Reader) provide standard ways of making use of IO. `std.ArrayList(u8)` has a `writer` method which gives us a writer. Let's use it.

```zig
test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}
```

Here we will use a reader to copy the file's contents into an allocated buffer. The second argument of [`readAllAlloc`](https://ziglang.org/documentation/master/std/#std;fs.File.Reader.readAllAlloc) is the maximum size that it may allocate; if the file is larger than this, it will return `error.StreamTooLong`.

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

    try expect(eql(u8, contents, message));
}
```

A common usecase for readers is to read until the next line (e.g. for user input). Here we will do this with the [`std.io.getStdIn()`](https://ziglang.org/documentation/master/std/#std;io.getStdIn) file.

```zig
fn nextLine(reader: anytype, buffer: []u8) !?[]const u8 {
    var line = (try reader.readUntilDelimiterOrEof(
        buffer,
        '\n',
    )) orelse return null;
    // trim annoying windows-only carriage return character
    if (@import("builtin").os.tag == .windows) {
        return std.mem.trimRight(u8, line, "\r");
    } else {
        return line;
    }
}

test "read until next line" {
    const stdout = std.io.getStdOut();
    const stdin = std.io.getStdIn();

    try stdout.writeAll(
        \\ Enter your name:
    );

    var buffer: [100]u8 = undefined;
    const input = (try nextLine(stdin.reader(), &buffer)).?;
    try stdout.writer().print(
        "Your name is: \"{s}\"\n",
        .{input},
    );
}
```

An [`std.io.Writer`](https://ziglang.org/documentation/master/std/#std;io.Writer) type consists of a context type, error set, and a write function. The write function must take in the context type and a byte slice. The write function must also return an error union of the Writer type's error set and the amount of bytes written. Let's create a type that implements a writer.

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
    try expect(eql(u8, bytes.items, "Hello Writer!"));
}
```

# Formatting

[`std.fmt`](https://ziglang.org/documentation/master/std/#std;fmt) provides ways to format data to and from strings.

A basic example of creating a formatted string. The format string must be compile time known. The `d` here denotes that we want a decimal number.

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

Take a moment to appreciate that you now know from top to bottom how printing hello world works. [`std.debug.print`](https://ziglang.org/documentation/master/std/#std;debug.print) works the same, except it writes to stderr and is protected by a mutex.

```zig
test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {s}!\n",
        .{"World"},
    );
}
```

We have used the `{s}` format specifier up until this point to print strings. Here we will use `{any}`, which gives us the default formatting.

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

Let's create a type with custom formatting by giving it a `format` function. This function must be marked as `pub` so that std.fmt can access it (more on packages later). You may notice the usage of `{s}` instead of `{}` - this is the format specifier for strings (more on format specifiers later). This is used here as `{}` defaults to array printing over string printing.

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

# JSON

Let's parse a json string into a struct type, using the streaming parser.

```zig
const Place = struct { lat: f32, long: f32 };

test "json parse" {
    var stream = std.json.TokenStream.init(
        \\{ "lat": 40.684540, "long": -74.401422 }
    );
    const x = try std.json.parse(Place, &stream, .{});

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
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
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expect(eql(
        u8,
        string.items,
        \\{"lat":5.19976654e+01,"long":-7.40687012e-01}
    ));
}
```

The json parser requires an allocator for javascript's string, array, and map types. This memory may be freed using [`std.json.parseFree`](https://ziglang.org/documentation/master/std/#std;json.parseFree).

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

    try expect(eql(u8, x.name, "Joe"));
    try expect(x.age == 25);
}
```

# Random Numbers

Here we create a new prng using a 64 bit random seed. a, b, c, and are given random values via this prng. The expressions giving c and d values are equivalent. `DefaultPrng` is `Xoroshiro128`; there are other prngs available in std.rand.

```zig
test "random numbers" {
    var prng = std.rand.DefaultPrng.init(blk: {
        var seed: u64 = undefined;
        try std.os.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });
    const rand = prng.random();

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused local constant compile error
    if (false) _ = .{ a, b, c, d }; 
}
```

Cryptographically secure random is also available.

```zig
test "crypto random numbers" {
    const rand = std.crypto.random;

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused local constant compile error
    if (false) _ = .{ a, b, c, d }; 
}
```

# Crypto

[`std.crypto`](https://ziglang.org/documentation/master/std/#std;crypto) includes many cryptographic utilities, including:
-  AES (Aes128, Aes256)
-  Diffie-Hellman key exchange (x25519)
-  Elliptic-curve arithmetic (curve25519, edwards25519, ristretto255)
-  Crypto secure hashing (blake2, Blake3, Gimli, Md5, sha1, sha2, sha3)
-  MAC functions (Ghash, Poly1305)
-  Stream ciphers (ChaCha20IETF, ChaCha20With64BitNonce, XChaCha20IETF, Salsa20, XSalsa20)

This list is inexhaustive. For more in-depth information, try [A tour of std.crypto in Zig 0.7.0 - Frank Denis](https://www.youtube.com/watch?v=9t6Y7KoCvyk).

# Threads

While Zig provides more advanced ways of writing concurrent and parallel code, [`std.Thread`](https://ziglang.org/documentation/master/std/#std;Thread) is available for making use of OS threads. Let's make use of an OS thread.

```zig
fn ticker(step: u8) void {
    while(true) {
        std.time.sleep(1 * std.time.ns_per_s);
        tick += @as(isize, step);
    }
}

var tick: isize = 0;

test "threading" {
    var thread = try std.Thread.spawn(.{}, ticker, .{@as(u8, 1)});
    _ = thread;
    try expect(tick == 0);
    std.time.sleep(3 * std.time.ns_per_s / 2);
    try expect(tick == 1);
}
```

Threads, however, aren't particularly useful without strategies for thread safety.

# Hash Maps

The standard library provides [`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#std;AutoHashMap), which lets you easily create a hash map type from a key type and a value type. These must be initiated with an allocator.

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

    try expect(map.count() == 4);

    var sum = Point{ .x = 0, .y = 0 };
    var iterator = map.iterator();

    while (iterator.next()) |entry| {
        sum.x += entry.value_ptr.x;
        sum.y += entry.value_ptr.y;
    }

    try expect(sum.x == 10);
    try expect(sum.y == -10);
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

    try expect(old.?.value == 10);
    try expect(map.get(255).? == 100);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#std;StringHashMap) is also provided for when you need strings as keys.

```zig
test "string hashmap" {
    var map = std.StringHashMap(enum { cool, uncool }).init(
        test_allocator,
    );
    defer map.deinit();

    try map.put("loris", .uncool);
    try map.put("me", .cool);

    try expect(map.get("me").? == .cool);
    try expect(map.get("loris").? == .uncool);
}
```

[`std.StringHashMap`](https://ziglang.org/documentation/master/std/#std;StringHashMap) and [`std.AutoHashMap`](https://ziglang.org/documentation/master/std/#std;AutoHashMap) are just wrappers for [`std.HashMap`](https://ziglang.org/documentation/master/std/#std;HashMap). If these two do not fulfil your needs, using [`std.HashMap`](https://ziglang.org/documentation/master/std/#std;HashMap) directly gives you much more control.

If having your elements backed by an array is wanted behaviour, try [`std.ArrayHashMap`](https://ziglang.org/documentation/master/std/#std;ArrayHashMap) and its wrapper [`std.AutoArrayHashMap`](https://ziglang.org/documentation/master/std/#std;AutoArrayHashMap).

# Stacks

[`std.ArrayList`](https://ziglang.org/documentation/master/std/#std;ArrayList) provides the methods necessary to use it as a stack. Here's an example of creating a list of matched brackets.

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
        try expect(std.meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable,
        }));
    }
}
```

# Sorting

The standard library provides utilities for in-place sorting slices. Its basic usage is as follows.

```zig
test "sorting" {
    var data = [_]u8{ 10, 240, 0, 0, 10, 5 };
    std.sort.sort(u8, &data, {}, comptime std.sort.asc(u8));
    try expect(eql(u8, &data, &[_]u8{ 0, 0, 5, 10, 10, 240 }));
    std.sort.sort(u8, &data, {}, comptime std.sort.desc(u8));
    try expect(eql(u8, &data, &[_]u8{ 240, 10, 10, 5, 0, 0 }));
}
```

[`std.sort.asc`](https://ziglang.org/documentation/master/std/#std;sort.asc) and [`.desc`](https://ziglang.org/documentation/master/std/#std;sort.desc) create a comparison function for the given type at comptime; if non-numerical types should be sorted, the user must provide their own comparison function.

[`std.sort.sort`](https://ziglang.org/documentation/master/std/#std;sort.sort) has a best case of O(n), and an average and worst case of O(n*log(n)).

# Iterators

It is a common idiom to have a struct type with a `next` function with an optional in its return type, so that the function may return a null to indicate that iteration is finished.

[`std.mem.SplitIterator`](https://ziglang.org/documentation/master/std/#std;mem.SplitIterator) (and the subtly different [`std.mem.TokenIterator`](https://ziglang.org/documentation/master/std/#std;mem.TokenIterator)) is an example of this pattern.
```zig
test "split iterator" {
    const text = "robust, optimal, reusable, maintainable, ";
    var iter = std.mem.split(u8, text, ", ");
    try expect(eql(u8, iter.next().?, "robust"));
    try expect(eql(u8, iter.next().?, "optimal"));
    try expect(eql(u8, iter.next().?, "reusable"));
    try expect(eql(u8, iter.next().?, "maintainable"));
    try expect(eql(u8, iter.next().?, ""));
    try expect(iter.next() == null);
}
```

Some iterators have a `!?T` return type, as opposed to ?T. `!?T` requires that we unpack the error union before the optional, meaning that the work done to get to the next iteration may error. Here is an example of doing this with a loop. [`cwd`](https://ziglang.org/documentation/master/std/#std;fs.cwd) has to be opened with iterate permissions in order for the directory iterator to work.

```zig
test "iterator looping" {
    var iter = (try std.fs.cwd().openDir(
        ".",
        .{ .iterate = true },
    )).iterate();

    var file_count: usize = 0;
    while (try iter.next()) |entry| {
        if (entry.kind == .File) file_count += 1;
    }

    try expect(file_count > 0);
}
```

`?!T` return types are also found, meaning the optional is unpacked before the error union. This conveys that getting to the next iteration is not the part that can fail, but rather getting the *value* of the next iteration may fail. [`std.process.ArgIterator`](https://ziglang.org/documentation/master/std/#std;process.ArgIterator) uses this pattern.

```zig
test "arg iteration" {
    var arg_characters: usize = 0;
    var iter = try std.process.argsWithAllocator(test_allocator);
    defer iter.deinit();
    while (iter.next()) |arg| {
        arg_characters += arg.len;
    }
    try expect(arg_characters > 0);
}
```

Here we will implement a custom iterator. This will iterate over a slice of strings, yielding the strings which contain a given string.

```zig
const ContainsIterator = struct {
    strings: []const []const u8,
    needle: []const u8,
    index: usize = 0,
    fn next(self: *ContainsIterator) ?[]const u8 {
        const index = self.index;
        for (self.strings[index..]) |string| {
            self.index += 1;
            if (std.mem.indexOf(u8, string, self.needle)) |_| {
                return string;
            }
        }
        return null;
    }
};

test "custom iterator" {
    var iter = ContainsIterator{
        .strings = &[_][]const u8{ "one", "two", "three" },
        .needle = "e",
    };

    try expect(eql(u8, iter.next().?, "one"));
    try expect(eql(u8, iter.next().?, "three"));
    try expect(iter.next() == null);
}
```

# Formatting specifiers
[`std.fmt`](https://ziglang.org/documentation/master/std/#std;fmt) provides options for formatting various data types.

`std.fmt.fmtSliceHexLower` and `std.fmt.fmtSliceHexUpper` provide hex formatting for strings as well as `{x}` and `{X}` for ints.
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

`std.fmt.fmtIntSizeDec` and `std.fmt.fmtIntSizeBin` output memory sizes in metric (1000) and power-of-two (1024) based notation.

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
        try bufPrint(&b, "{*}", .{@intToPtr(*u8, 0xDEADBEEF)}),
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
    try expect(eql(
        u8,
        try bufPrint(&b, "{0s}{0s}{1s}", .{"a", "b"}),
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

# End of Chapter 2

This chapter is incomplete. In the future it will contain things such as:

- Arbitrary Precision Maths
- Linked Lists
- Queues
- Mutexes
- Atomics
- Searching
- Logging

Feedback and PRs are welcome.
