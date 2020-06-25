---
title: "Chapter 2 - Standard Patterns"
weight: 3
date: 2020-06-25 13:34:09
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
    try out_file.outStream().print(
        "Hello, {}!\n", 
        .{"World"}
    );
}
```

# End of Chapter 2

This chapter is incomplete. In the future it will contain things such as:

- Json
- Hash maps
- Arbitrary Precision Maths
- Linked Lists
- Randomness
- Crypto
- Stacks
- Queues
- Threads
- Mutexes
- Atomics
- Searching
- Sorting
- Logging

The nest chapter is planned to cover the build system. Feedback and PRs are welcome.