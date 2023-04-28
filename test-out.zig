const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit() == .leak) @panic("leaked");

    const files = .{
        .{ "chapter-0.md", "test-c0.zig" },
        .{ "chapter-1.md", "test-c1.zig" },
        .{ "chapter-2.md", "test-c2.zig" },
        .{ "chapter-3.md", "test-c3.zig" },
        .{ "chapter-4.md", "test-c4.zig" },
        .{ "chapter-5.md", "test-c5.zig" },
    };

    std.fs.cwd().makeDir("test-out") catch |err| switch (err) {
        error.PathAlreadyExists => {},
        else => return err,
    };

    const out_dir = try std.fs.cwd().openDir("test-out", .{});

    inline for (files) |f| {
        const in = try std.fs.cwd().openFile(f[0], .{});
        defer in.close();

        const out = try out_dir.createFile(f[1], .{});
        defer out.close();

        const text = try allocator.alloc(u8, (try in.stat()).size);
        defer allocator.free(text);
        _ = try in.readAll(text);

        var iter = std.mem.split(u8, text, "```");
        outer: while (iter.next()) |token| {
            if (!std.mem.startsWith(u8, token, "zig")) continue;

            // skip tests with special prefixes
            for (&[_][]const u8{
                "<!--no_test-->\n", // this should not be run as a test
                "<!--fail_test-->\n", // this test should fail TODO: actually check that these tests fail
            }) |skip_prefix| {
                const offset = @ptrToInt(token.ptr) - @ptrToInt(text.ptr);
                if (offset >= skip_prefix.len + "```".len) {
                    if (std.mem.eql(
                        u8,
                        skip_prefix,
                        @intToPtr([*]const u8, @ptrToInt(token.ptr) - (skip_prefix.len + "```".len))[0..skip_prefix.len],
                    )) continue :outer;
                }
            }

            const this_test = std.mem.trim(u8, token[3..], " \n\t");
            try out.writer().print("{s}\n\n", .{this_test});
        }
    }
}
