// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "scientific" {
    var b: [16]u8 = undefined;

    try expect(eql(
        u8,
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e+00",
    ));
}
