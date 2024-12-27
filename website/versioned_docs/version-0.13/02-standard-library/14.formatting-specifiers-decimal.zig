// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "decimal float" {
    var b: [4]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{d}", .{16.5}),
        "16.5",
    ));
}
