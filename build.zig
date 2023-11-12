const std = @import("std");

/// Returns paths to all files inside website/docs with a .zig extension
fn getAllTestPaths(allocator: std.mem.Allocator) ![][]const u8 {
    var test_file_paths = std.ArrayList([]const u8).init(allocator);
    errdefer {
        for (test_file_paths.items) |test_path| allocator.free(test_path);
        test_file_paths.deinit();
    }
    {
        var dirs = try std.fs.cwd().openIterableDir("website/docs", .{});
        defer dirs.close();
        var walker = try dirs.walk(allocator);
        while (try walker.next()) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

            try test_file_paths.append(try allocator.dupe(u8, entry.path));
        }
    }

    return test_file_paths.toOwnedSlice();
}

/// Returns a generated file as an entrypoint for testing
fn generateMainTestFile(allocator: std.mem.Allocator, test_file_paths: [][]const u8) ![]u8 {
    var out_file = std.ArrayList(u8).init(allocator);

    try out_file.appendSlice("const std = @import(\"std\");\n");
    for (test_file_paths) |test_path| {
        try out_file.writer().print(
            "pub const A{X} = @import(\"website/docs/{s}\");\n",
            .{ std.hash.Wyhash.hash(0, test_path), test_path },
        );
    }
    try out_file.appendSlice("comptime { std.testing.refAllDecls(@This()); }\n");

    return out_file.toOwnedSlice();
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_file_paths = try getAllTestPaths(b.allocator);
    defer {
        for (test_file_paths) |test_path| b.allocator.free(test_path);
        b.allocator.free(test_file_paths);
    }
    const out_file = try generateMainTestFile(b.allocator, test_file_paths);
    defer b.allocator.free(out_file);

    // write out our main testing file to zig-cache
    const write_files = b.addWriteFiles();
    const test_lazypath = write_files.add("test-main.zig", out_file);

    // copy our zig test files from website/docs into zig-cache
    for (test_file_paths) |test_file_path| {
        const path = b.fmt("website/docs/{s}", .{test_file_path});
        _ = write_files.addCopyFile(.{ .path = path }, path);
    }

    const unit_tests = b.addTest(.{
        .root_source_file = test_lazypath,
        .target = target,
        .optimize = optimize,
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
}
