// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const allocator = std.testing.allocator;

test "arraylist" {
    var list: ArrayList(u8) = .empty;
    defer list.deinit(allocator);
    try list.append(allocator, 'H');
    try list.append(allocator, 'e');
    try list.append(allocator, 'l');
    try list.append(allocator, 'l');
    try list.append(allocator, 'o');
    try list.appendSlice(allocator, " World!");

    try expect(eql(u8, list.items, "Hello World!"));
}
