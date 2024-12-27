// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "position" {
    var b: [3]u8 = undefined;

    try expectEqualStrings(
        "aab",
        try bufPrint(&b, "{0s}{0s}{1s}", .{ "a", "b" }),
    );
}
