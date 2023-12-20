// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
const eql = std.mem.eql;
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

    try expect(eql(u8, list.items, "Hello World!"));
}
