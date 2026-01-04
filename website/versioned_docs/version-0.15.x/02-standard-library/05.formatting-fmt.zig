// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
// hide-end
const test_allocator = std.testing.allocator;

test "fmt" {
    const string = try std.fmt.allocPrint(
        test_allocator,
        "{d} + {d} = {d}",
        .{ 9, 10, 19 },
    );
    defer test_allocator.free(string);

    try expect(eql(u8, string, "9 + 10 = 19"));
}
