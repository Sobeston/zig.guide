// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "decimal float" {
    var b: [4]u8 = undefined;
    try expectEqualStrings(
        "16.5",
        try bufPrint(&b, "{d}", .{16.5}),
    );
}
