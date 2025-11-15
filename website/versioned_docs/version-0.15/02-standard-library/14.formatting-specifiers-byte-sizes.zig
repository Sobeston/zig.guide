// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "B Bi" {
    var b: [32]u8 = undefined;

    try expectEqualStrings("1B", try bufPrint(&b, "{B}", .{1}));
    try expectEqualStrings("1B", try bufPrint(&b, "{Bi}", .{1}));

    try expectEqualStrings("1.024kB", try bufPrint(&b, "{B}", .{1024}));
    try expectEqualStrings("1KiB", try bufPrint(&b, "{Bi}", .{1024}));

    try expectEqualStrings(
        "1.073741824GB",
        try bufPrint(&b, "{B}", .{1024 * 1024 * 1024}),
    );
    try expectEqualStrings(
        "1GiB",
        try bufPrint(&b, "{Bi}", .{1024 * 1024 * 1024}),
    );
}
