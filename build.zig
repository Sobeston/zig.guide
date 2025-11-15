//! This build.zig is a bit cursed, namely as it attempts to be compatible with all versions of Zig
//! used within the guide.

const std = @import("std");
const zig_version = @import("builtin").zig_version;

// Used for any unversioned content (for now just /blog)
const current_minor_version = 13;

const version_path = std.fmt.comptimePrint(
    "website/versioned_docs/version-0.{}/",
    .{zig_version.minor},
);

const max_files: usize = 2048;
const max_path_len: usize = 512;
var path_storage: [max_files][max_path_len]u8 = undefined;
var test_file_paths_store: [max_files][]const u8 = undefined;

fn storePath(src: []const u8, path_count: usize) !void {
    if (path_count >= max_files)
        return error.TooManyFiles;
    if (src.len >= max_path_len)
        return error.PathTooLong;

    std.mem.copyForwards(u8, &path_storage[path_count], src);
    test_file_paths_store[path_count] = path_storage[path_count][0..src.len];
}

/// Returns paths to all files inside version_path with a .zig extension.
/// Also tests /blog when current_minor_version is detected.
fn getAllTestPaths(root_dir: std.fs.Dir, allocator: std.mem.Allocator) ![][]const u8 {
    var path_count: usize = 0;

    {
        var dirs = try switch (zig_version.minor) {
            11 => root_dir.openIterableDir(version_path, .{}),
            else => root_dir.openDir(version_path, .{ .iterate = true }),
        };
        defer dirs.close();
        var walker = try dirs.walk(allocator);
        while (try walker.next()) |entry| {
            if (entry.kind != .file) continue;
            if (!std.mem.endsWith(u8, entry.path, ".zig")) continue;

            const qualified_path = try std.fs.path.join(
                allocator,
                &[_][]const u8{ version_path, entry.path },
            );

            try storePath(qualified_path, path_count);
            path_count += 1;
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

            try storePath(qualified_path, path_count);
            path_count += 1;
        }
    }

    return test_file_paths_store[0..path_count];
}

const max_output = 200_000;
var main_test_file_buf: [max_output]u8 = undefined;

/// Returns a generated file as an entrypoint for testing
fn generateMainTestFile(test_file_paths: [][]const u8) ![]u8 {
    var used: usize = 0;
    const import_line = "const std = @import(\"std\");\n";
    std.mem.copyForwards(u8, main_test_file_buf[used..], import_line);
    used += import_line.len;
    for (test_file_paths) |test_path| {
        var fbs = std.io.fixedBufferStream(main_test_file_buf[used..]);
        try fbs.writer().print("pub const A{X} = @import(\"{s}\");\n", .{ std.hash.Wyhash.hash(0, test_path), test_path });
        const written = fbs.getWritten().len;
        used += written;
    }

    const ending_line = "comptime { std.testing.refAllDecls(@This()); }\n";
    std.mem.copyForwards(u8, main_test_file_buf[used..], ending_line);
    used += ending_line.len;
    return main_test_file_buf[0..used];
}

pub fn build(b: *std.Build) !void {
    std.log.warn("Zig 0.{}.x detected, importing " ++ version_path, .{zig_version.minor});

    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const test_file_paths = try getAllTestPaths(b.build_root.handle, b.allocator);
    const out_file = try generateMainTestFile(test_file_paths);

    // write out our main testing file to zig-cache
    const write_files = b.addWriteFiles();
    const test_lazypath = write_files.add("test-main.zig", out_file);

    // copy our zig test files from version_path into zig-cache
    for (test_file_paths) |test_file_path| {
        const path = b.fmt("{s}", .{test_file_path});
        // TODO: don't use cwd_relative...
        _ = write_files.addCopyFile(.{ .cwd_relative = path }, path);
    }

    const unit_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = test_lazypath,
        .target = target,
        .optimize = optimize,
    }) });

    const run_unit_tests = b.addRunArtifact(unit_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);

    const fmt_paths = try b.allocator.alloc([]const u8, 1);
    fmt_paths[0] = b.build_root.path orelse ".";
    const fmt = b.addFmt(.{ .paths = fmt_paths, .check = true });
    const fmt_step = b.step("fmt", "Test all files for correct formatting");
    fmt_step.dependOn(&fmt.step);

    const dir_logger = DebugDirLogger.create(b);
    dir_logger.step.dependOn(&write_files.step);

    const test_with_fmt = b.step("test-with-fmt", "Run unit tests & test all files for correct formatting");
    test_with_fmt.dependOn(test_step);
    test_with_fmt.dependOn(fmt_step);
    test_with_fmt.dependOn(&dir_logger.step);

    b.default_step = test_with_fmt;
}

const WriteFileStep = switch (zig_version.minor) {
    11 => std.build.WriteFileStep,
    else => std.Build.Step.WriteFile,
};

/// Logs the output directory of its WriteFileStep dependency.
const DebugDirLogger = struct {
    step: std.Build.Step,
    pub fn create(owner: *std.Build) *DebugDirLogger {
        const ds = owner.allocator.create(DebugDirLogger) catch @panic("OOM");
        ds.* = .{
            .step = std.Build.Step.init(.{
                .id = .custom,
                .name = "debug-dir-logger",
                .owner = owner,
                .makeFn = switch (zig_version.minor) {
                    11 => makeZig0_11,
                    12 => makeZig0_12,
                    13 => makeZig0_13,
                    14 => makeZig0_14,
                    15 => makeZig0_15,
                    else => makeZig0_15,
                },
            }),
        };
        return ds;
    }

    /// Bad hack to work on 0.11 and later major versions
    /// We can't use the real @fieldParentPtr in this file as its parameters
    /// changed in 0.12.
    fn fieldParentPtr(step: *std.Build.Step) *WriteFileStep {
        return @ptrFromInt(@intFromPtr(step) - @offsetOf(WriteFileStep, "step"));
    }

    fn makeZig0_11(step: *std.Build.Step, _: *std.Progress.Node) !void {
        const dependency = step.dependencies.items[0];
        if (dependency.id != .write_file) unreachable; // DebugDirLogger only supports a WriteFileStep dependency

        std.log.debug(
            "test-dir at {s}",
            .{fieldParentPtr(dependency).generated_directory.path.?},
        );
    }

    fn makeZig0_12(step: *std.Build.Step, _: *std.Progress.Node) !void {
        try makeZig(step);
    }

    fn makeZig0_13(step: *std.Build.Step, _: std.Progress.Node) !void {
        try makeZig(step);
    }

    fn makeZig0_14(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
        try makeZig(step);
    }

    fn makeZig0_15(step: *std.Build.Step, _: std.Build.Step.MakeOptions) !void {
        try makeZig(step);
    }

    fn makeZig(step: *std.Build.Step) !void {
        const dependency = step.dependencies.items[0];
        if (dependency.id != .write_file) unreachable; // DebugDirLogger only supports a WriteFileStep dependency
        std.log.debug(
            "test-dir at {s}",
            .{fieldParentPtr(dependency).generated_directory.path.?},
        );
    }
};
