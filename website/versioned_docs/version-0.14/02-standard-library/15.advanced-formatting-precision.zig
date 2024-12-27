// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "precision" {
    var b: [4]u8 = undefined;
    try expectEqualStrings(
        "3.14",
        try bufPrint(&b, "{d:.2}", .{3.14159}),
    );
}
