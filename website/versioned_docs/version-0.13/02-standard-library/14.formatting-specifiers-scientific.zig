// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "scientific" {
    var b: [16]u8 = undefined;

    try expectEqualStrings(
        try bufPrint(&b, "{e}", .{3.14159}),
        "3.14159e0",
    );
}
