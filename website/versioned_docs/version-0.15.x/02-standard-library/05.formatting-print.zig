// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const allocator = std.testing.allocator;
// hide-end
test "print" {
    var list: std.ArrayList(u8) = .empty;
    defer list.deinit(allocator);
    try list.print(
        allocator,
        "{} + {} = {}",
        .{ 9, 10, 19 },
    );
    try expect(eql(u8, list.items, "9 + 10 = 19"));
}
