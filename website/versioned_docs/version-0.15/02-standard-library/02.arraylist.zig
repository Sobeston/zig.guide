// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
const eql = std.mem.eql;
const ArrayList = std.ArrayList;
const test_allocator = std.testing.allocator;

test "arraylist" {
    var list: ArrayList(u8) = .empty;
    defer list.deinit(test_allocator);
    try list.append(test_allocator, 'H');
    try list.append(test_allocator, 'e');
    try list.append(test_allocator, 'l');
    try list.append(test_allocator, 'l');
    try list.append(test_allocator, 'o');
    try list.appendSlice(test_allocator, " World!");

    try expect(eql(u8, list.items, "Hello World!"));
}
