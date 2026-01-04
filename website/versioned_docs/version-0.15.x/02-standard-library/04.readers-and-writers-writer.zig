// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
// hide-end
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "io writer usage" {
    var list = ArrayList(u8).init(test_allocator);
    defer list.deinit();
    const bytes_written = try list.writer().write(
        "Hello World!",
    );
    try expect(bytes_written == 12);
    try expect(eql(u8, list.items, "Hello World!"));
}
