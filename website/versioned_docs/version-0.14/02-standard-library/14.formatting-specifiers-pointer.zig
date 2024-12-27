// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expect(eql(
        u8,
        try bufPrint(&b, "{*}", .{@as(*u8, @ptrFromInt(0xDEADBEEF))}),
        "u8@deadbeef",
    ));
}
