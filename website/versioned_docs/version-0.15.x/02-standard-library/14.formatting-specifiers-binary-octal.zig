// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "binary, octal fmt" {
    var b: [8]u8 = undefined;

    try expectEqualStrings(
        "11111110",
        try bufPrint(&b, "{b}", .{254}),
    );

    try expectEqualStrings(
        "376",
        try bufPrint(&b, "{o}", .{254}),
    );
}
