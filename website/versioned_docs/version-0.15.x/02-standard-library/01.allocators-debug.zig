// hide-start
const std = @import("std");
const expect = std.testing.expect;

// hide-end
test "DebugAllocator" {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    const allocator = gpa.allocator();
    defer {
        const deinit_status = gpa.deinit();
        //fail test; can't try in defer as defer is executed after we return
        if (deinit_status == .leak) expect(false) catch @panic("TEST FAIL");
    }

    const bytes = try allocator.alloc(u8, 100);
    defer allocator.free(bytes);
}
