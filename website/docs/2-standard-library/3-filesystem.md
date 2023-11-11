# Filesystem

Let's create and open a file in our current working directory, write to it, and
then read from it. Here we have to use `.seekTo` to go back to the start of the
file before reading what we have written.

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

The functions
[`std.fs.openFileAbsolute`](https://ziglang.org/documentation/master/std/#A;std:fs.openFileAbsolute)
and similar absolute functions exist, but we will not test them here.

We can get various information about files by using `.stat()` on them. `Stat`
also contains fields for .inode and .mode, but they are not tested here as they
rely on the current OS' types.

```zig
test "file stat" {
    const file = try std.fs.cwd().createFile(
        "junk_file2.txt",
        .{ .read = true },
    );
    defer file.close();
    const stat = try file.stat();
    try expect(stat.size == 0);
    try expect(stat.kind == .file);
    try expect(stat.ctime <= std.time.nanoTimestamp());
    try expect(stat.mtime <= std.time.nanoTimestamp());
    try expect(stat.atime <= std.time.nanoTimestamp());
}
```

We can make directories and iterate over their contents. Here we will use an
iterator (discussed later). This directory (and its contents) will be deleted
after this test finishes.

```zig
test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    var iter_dir = try std.fs.cwd().openIterableDir(
        "test-tmp",
        .{},
    );
    defer {
        iter_dir.close();
        std.fs.cwd().deleteTree("test-tmp") catch unreachable;
    }

    _ = try iter_dir.dir.createFile("x", .{});
    _ = try iter_dir.dir.createFile("y", .{});
    _ = try iter_dir.dir.createFile("z", .{});

    var file_count: usize = 0;
    var iter = iter_dir.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file) file_count += 1;
    }

    try expect(file_count == 3);
}
```
