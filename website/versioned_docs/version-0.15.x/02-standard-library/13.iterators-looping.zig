// hide-start
const std = @import("std");
const expect = std.testing.expect;
// hide-end
test "iterator looping" {
    var cwd = try std.fs.cwd().openDir(".", .{
        .iterate = true,
    });
    defer cwd.close();

    var file_count: usize = 0;

    var iter = cwd.iterate();
    while (try iter.next()) |entry| {
        if (entry.kind == .file) file_count += 1;
    }

    try expect(file_count > 0);
}
