// hide-start
const std = @import("std");
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
const fmtIntSizeDec = std.fmt.fmtIntSizeDec;
const fmtIntSizeBin = std.fmt.fmtIntSizeBin;

test "B Bi" {
    var b: [32]u8 = undefined;

    try expectEqualStrings("1B", try bufPrint(&b, "{}", .{fmtIntSizeDec(1)}));
    try expectEqualStrings("1B", try bufPrint(&b, "{}", .{fmtIntSizeBin(1)}));

    try expectEqualStrings("1.024kB", try bufPrint(&b, "{}", .{fmtIntSizeDec(1024)}));
    try expectEqualStrings("1KiB", try bufPrint(&b, "{}", .{fmtIntSizeBin(1024)}));

    try expectEqualStrings(
        "1.073741824GB",
        try bufPrint(&b, "{}", .{fmtIntSizeDec(1024 * 1024 * 1024)}),
    );
    try expectEqualStrings(
        "1GiB",
        try bufPrint(&b, "{}", .{fmtIntSizeBin(1024 * 1024 * 1024)}),
    );
}
