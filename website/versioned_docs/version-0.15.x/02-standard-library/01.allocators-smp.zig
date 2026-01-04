// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
test "SmpAllocator" {
    const allocator = std.heap.smp_allocator;

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}
