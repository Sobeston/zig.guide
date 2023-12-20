// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
test "allocator create/destroy" {
    const byte = try std.heap.page_allocator.create(u8);
    defer std.heap.page_allocator.destroy(byte);
    byte.* = 128;
}
