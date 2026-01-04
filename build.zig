// TODO: redo this build.zig, it originally supported every compiler version. I can't be bothered
// with that anymore.

const std = @import("std");
const zig_version = @import("builtin").zig_version;

// Used for any unversioned content (for now just /blog)
const current_minor_version = 15;

const base_version_path = "website/versioned_docs/version-";
const version_path = switch (zig_version.minor) {
    11 => base_version_path ++ "0.11",
    12 => base_version_path ++ "0.12",
    13 => base_version_path ++ "0.13",
    // 14
    15 => base_version_path ++ "0.15.x",
    16 => base_version_path ++ "0.16.x",
    else => @compileError("Unknown version"),
};

const Dir = if (zig_version.minor >= 16) std.Io.Dir else std.fs.Dir;
const Io = if (zig_version.minor >= 16) std.Io else void;

/// Returns paths to all files inside version_path with a .zig extension.
/// Also tests /blog when current_minor_version is detected.
fn getAllTestPaths(root_dir: Dir, allocator: std.mem.Allocator, io: Io) ![][]const u8 {
    var test_file_paths: std.ArrayList([]const u8) = .empty;
    errdefer {
        for (test_file_paths.items) |test_path| allocator.free(test_path);
        test_file_paths.deinit(allocator);
    }
    {
        var dirs = try switch (zig_version.minor) {
            11 => root_dir.openIterableDir(version_path, .{}),
            12...15 => root_dir.openDir(version_path, .{ .iterate = true }),
            else => root_dir.openDir(io, version_path, .{ .iterate = true }),
        };
        defer if (zig_version.minor >= 16) dirs.close(io) else dirs.close();

        var walker = try dirs.walk(allocator);
        while (try if (zig_version.minor >= 16)
            walker.next(io)
        else
            walker.next()) |entry|
        {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

            const qualified_path = try std.fs.path.join(
                allocator,
                &[_][]const u8{ version_path, entry.path },
            );

            try test_file_paths.append(allocator, qualified_path);
        }
    }

    if (zig_version.minor != current_minor_version) {
        std.log.warn("Zig 0.{}.x detected, skipping testing /blog content (requires Zig 0.{}.x)", .{
            zig_version.minor,
            current_minor_version,
        });
    } else {
        std.log.info("Zig 0.{}.x detected, testing /blog content", .{
            zig_version.minor,
        });
        const blog_path = "website/blog";
        var dirs = try switch (zig_version.minor) {
            11 => root_dir.openIterableDir(blog_path, .{}),
            else => root_dir.openDir(blog_path, .{ .iterate = true }),
        };
        defer dirs.close();
        var walker = try dirs.walk(allocator);
        while (try walker.next()) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

            const qualified_path = try std.fs.path.join(
                allocator,
                &[_][]const u8{ blog_path, entry.path },
            );

            try test_file_paths.append(allocator, qualified_path);
        }
    }

    return test_file_paths.toOwnedSlice(allocator);
}

/// Returns a generated file as an entrypoint for testing
fn generateMainTestFile(allocator: std.mem.Allocator, test_file_paths: [][]const u8) ![]u8 {
    var out_file: std.ArrayList(u8) = .empty;

    try out_file.appendSlice(allocator, "const std = @import(\"std\");\n");
    for (test_file_paths) |test_path| {
        try out_file.print(
            allocator,
            "pub const A{X} = @import(\"{s}\");\n",
            .{ std.hash.Wyhash.hash(0, test_path), test_path },
        );
    }
    try out_file.appendSlice(allocator, "comptime { std.testing.refAllDecls(@This()); }\n");

    return out_file.toOwnedSlice(allocator);
}

pub fn build(b: *std.Build) !void {
    std.log.warn("Zig 0.{}.x detected, importing " ++ version_path, .{zig_version.minor});

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const io = if (zig_version.minor >= 16) b.graph.io else {};

    const test_file_paths = try getAllTestPaths(b.build_root.handle, b.allocator, io);
    defer {
        for (test_file_paths) |test_path| b.allocator.free(test_path);
        b.allocator.free(test_file_paths);
    }
    const out_file = try generateMainTestFile(b.allocator, test_file_paths);
    defer b.allocator.free(out_file);

    // write out our main testing file to zig-cache
    const write_files = b.addWriteFiles();
    const test_lazypath = write_files.add("test-main.zig", out_file);

    // copy our zig test files from version_path into zig-cache
    for (test_file_paths) |test_file_path| {
        const path = b.fmt("{s}", .{test_file_path});
        // TODO: don't use cwd_relative...
        _ = write_files.addCopyFile(.{ .cwd_relative = path }, path);
    }

    const unit_tests = b.addTest(.{
        .root_module = b.addModule("tests", .{
            .root_source_file = test_lazypath,
            .target = target,
            .optimize = optimize,
        }),
    });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const fmt_paths = try b.allocator.alloc([]const u8, 1);
    fmt_paths[0] = b.build_root.path orelse ".";
    const fmt = b.addFmt(.{ .paths = fmt_paths, .check = true });
    const fmt_step = b.step("fmt", "Test all files for correct formatting");
    fmt_step.dependOn(&fmt.step);

    const test_with_fmt = b.step("test-with-fmt", "Run unit tests & test all files for correct formatting");
    test_with_fmt.dependOn(test_step);
    test_with_fmt.dependOn(fmt_step);

    b.default_step = test_with_fmt;
}
