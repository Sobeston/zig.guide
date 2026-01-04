// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
// hide-end
const ArrayList = std.ArrayList;
const allocator = std.testing.allocator;

test "io writer usage" {
    var list: ArrayList(u8) = .empty;
    defer list.deinit(allocator);

    try list.print(allocator, "Hello {s}!", .{"World"});

    try expect(eql(u8, list.items, "Hello World!"));
}
