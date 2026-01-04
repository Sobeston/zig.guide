// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "ascii fmt" {
    var b: [1]u8 = undefined;
    try expectEqualStrings(
        "B",
        try bufPrint(&b, "{c}", .{66}),
    );
}
