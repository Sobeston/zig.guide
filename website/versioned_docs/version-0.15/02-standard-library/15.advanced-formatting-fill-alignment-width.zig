// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "fill, alignment, width" {
    var b: [6]u8 = undefined;

    try expectEqualStrings(
        "hi!  ",
        try bufPrint(&b, "{s: <5}", .{"hi!"}),
    );

    try expectEqualStrings(
        "_hi!__",
        try bufPrint(&b, "{s:_^6}", .{"hi!"}),
    );

    try expectEqualStrings(
        "!hi!",
        try bufPrint(&b, "{s:!>4}", .{"hi!"}),
    );
}
