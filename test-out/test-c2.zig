const std = @import("std");
const expect = std.testing.expect;

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    const allocator = fba.allocator();

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    try expect(memory.len == 100);
    try expect(@TypeOf(memory) == []u8);
}

test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    _ = try allocator.alloc(u8, 1);
    _ = try allocator.alloc(u8, 10);
    _ = try allocator.alloc(u8, 100);
}

test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}

test "GPA" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}

const expectEqualSlices = std.testing.expectEqualSlices;
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

    try expectEqualSlices(u8, list.items, "Hello World!");
}

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

    try expectEqualSlices(u8, buffer[0..bytes_read], "Hello File!");
}

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

test "make dir" {
    try std.fs.cwd().makeDir("test-tmp");
    const iter_dir = try std.fs.cwd().openIterableDir(
        "test-tmp",
        .{},
    );
    defer {
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

test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expectEqualSlices(u8, list.items, "Hello World!");
}

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

    try expectEqualSlices(u8, contents, message);
}

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
        self.items = self.data[0 .. self.items.len + data.len];
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
    try expectEqualSlices(u8, bytes.items, "Hello Writer!");
}

test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{d} + {d} = {d}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    try expectEqualSlices(u8, string, "9 + 10 = 19");
}

test "print" {
    var list = std.ArrayList(u8).init(test_allocator);
    defer list.deinit();
    try list.writer().print(
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    try expectEqualSlices(u8, list.items, "9 + 10 = 19");
}

test "hello world" {
    const out_file = std.io.getStdOut();
    try out_file.writer().print(
        "Hello, {s}!\n",
        .{"World"},
    );
}

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

    try expectEqualSlices(
        u8,
        string,
        "{ 1, 4 } + { 2, 5 } = { 3, 9 }",
    );
}

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

    try expectEqualSlices(
        u8,
        john_string,
        "John Carmack (1970-)",
    );

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

    try expectEqualSlices(
        u8,
        claude_string,
        "Claude Shannon (1916-2001)",
    );
}

const Place = struct { lat: f32, long: f32 };

test "json parse" {
    const parsed = try std.json.parseFromSlice(Place, test_allocator,
        \\{ "lat": 40.684540, "long": -74.401422 }
    , .{});
    defer parsed.deinit();
    const x = parsed.value;

    try expect(x.lat == 40.684540);
    try expect(x.long == -74.401422);
}

test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expectEqualSlices(u8, string.items,
        \\{"lat":5.199766540527344e+01,"long":-7.406870126724243e-01}
    );
}

test "json parse with strings" {
    const User = struct { name: []u8, age: u16 };
    // TODO: Use leaky?
    const parsed = try std.json.parseFromSlice(User, test_allocator,
        \\{ "name": "Joe", "age": 25 }
    , .{});
    defer parsed.deinit();
    const x = parsed.value;

    try expectEqualSlices(u8, x.name, "Joe");
    try expect(x.age == 25);
}

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

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}

test "crypto random numbers" {
    const rand = std.crypto.random;

    const a = rand.float(f32);
    const b = rand.boolean();
    const c = rand.int(u8);
    const d = rand.intRangeAtMost(u8, 0, 255);

    //suppress unused constant compile error
    _ = .{ a, b, c, d };
}

fn ticker(step: u8) void {
    while (true) {
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

    for (string, 0..) |char, i| {
        if (char == '(') try stack.append(i);
        if (char == ')')
            try pairs.append(.{
                .open = stack.pop(),
                .close = i,
            });
    }

    for (pairs.items, 0..) |pair, i| {
        try expect(std.meta.eql(pair, switch (i) {
            0 => Pair{ .open = 1, .close = 2 },
            1 => Pair{ .open = 3, .close = 4 },
            2 => Pair{ .open = 0, .close = 5 },
            else => unreachable,
        }));
    }
}

test "sorting" {
    var data = [_]u8{ 10, 240, 0, 0, 10, 5 };
    std.mem.sort(u8, &data, {}, comptime std.sort.asc(u8));
    try expectEqualSlices(u8, &data, &[_]u8{ 0, 0, 5, 10, 10, 240 });
    std.mem.sort(u8, &data, {}, comptime std.sort.desc(u8));
    try expectEqualSlices(u8, &data, &[_]u8{ 240, 10, 10, 5, 0, 0 });
}

test "split iterator" {
    const text = "robust, optimal, reusable, maintainable, ";
    var iter = std.mem.split(u8, text, ", ");
    try expectEqualSlices(u8, iter.next().?, "robust");
    try expectEqualSlices(u8, iter.next().?, "optimal");
    try expectEqualSlices(u8, iter.next().?, "reusable");
    try expectEqualSlices(u8, iter.next().?, "maintainable");
    try expectEqualSlices(u8, iter.next().?, "");
    try expect(iter.next() == null);
}

test "iterator looping" {
    var iter = (try std.fs.cwd().openIterableDir(
        ".",
        .{},
    )).iterate();

    var file_count: usize = 0;
    while (try iter.next()) |entry| {
        if (entry.kind == .file) file_count += 1;
    }

    try expect(file_count > 0);
}

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

    try expectEqualSlices(u8, iter.next().?, "one");
    try expectEqualSlices(u8, iter.next().?, "three");
    try expect(iter.next() == null);
}

const bufPrint = std.fmt.bufPrint;

test "hex" {
    var b: [8]u8 = undefined;

    _ = try bufPrint(&b, "{X}", .{4294967294});
    try expectEqualSlices(u8, &b, "FFFFFFFE");

    _ = try bufPrint(&b, "{x}", .{4294967294});
    try expectEqualSlices(u8, &b, "fffffffe");

    _ = try bufPrint(&b, "{}", .{std.fmt.fmtSliceHexLower("Zig!")});
    try expectEqualSlices(u8, &b, "5a696721");
}

test "decimal float" {
    var b: [4]u8 = undefined;
    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{d}", .{16.5}),
        "16.5",
    );
}

test "ascii fmt" {
    var b: [1]u8 = undefined;
    _ = try bufPrint(&b, "{c}", .{66});
    try expectEqualSlices(u8, &b, "B");
}

test "B Bi" {
    var b: [32]u8 = undefined;

    try expectEqualSlices(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1)}), "1B");
    try expectEqualSlices(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1)}), "1B");

    try expectEqualSlices(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024)}), "1.024kB");
    try expectEqualSlices(u8, try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024)}), "1KiB");

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeDec(1024 * 1024 * 1024)}),
        "1.073741824GB",
    );
    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{}", .{std.fmt.fmtIntSizeBin(1024 * 1024 * 1024)}),
        "1GiB",
    );
}

test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{b}", .{254}),
        "11111110",
    );

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{o}", .{254}),
        "376",
    );
}

test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{*}", .{@as(*u8, @ptrFromInt(0xDEADBEEF))}),
        "u8@deadbeef",
    );
}

test "scientific" {
    var b: [16]u8 = undefined;

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    );
}

test "string fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{s}", .{hello}),
        "hello!",
    );
}

test "position" {
    var b: [3]u8 = undefined;
    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{0s}{0s}{1s}", .{ "a", "b" }),
        "aab",
    );
}

test "fill, alignment, width" {
    var b: [6]u8 = undefined;

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{s: <5}", .{"hi!"}),
        "hi!  ",
    );

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{s:_^6}", .{"hi!"}),
        "_hi!__",
    );

    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{s:!>4}", .{"hi!"}),
        "!hi!",
    );
}

test "precision" {
    var b: [4]u8 = undefined;
    try expectEqualSlices(
        u8,
        try bufPrint(&b, "{d:.2}", .{3.14159}),
        "3.14",
    );
}

