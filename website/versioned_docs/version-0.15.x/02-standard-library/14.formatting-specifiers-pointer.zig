// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "pointer fmt" {
    var b: [16]u8 = undefined;
    try expectEqualStrings(
        "u8@deadbeef",
        try bufPrint(&b, "{*}", .{@as(*u8, @ptrFromInt(0xDEADBEEF))}),
    );
}
