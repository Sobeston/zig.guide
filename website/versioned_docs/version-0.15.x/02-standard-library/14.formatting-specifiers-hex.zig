// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;

// hide-end
const bufPrint = std.fmt.bufPrint;
const expectEqualStrings = std.testing.expectEqualStrings;

test "hex" {
    var b: [10]u8 = undefined;

    try expectEqualStrings(
        "FFFFFFFE",
        try bufPrint(&b, "{X}", .{4294967294}),
    );

    try expectEqualStrings(
        "fffffffe",
        try bufPrint(&b, "{x}", .{4294967294}),
    );

    try expectEqualStrings(
        "0xAAAAAAAA",
        try bufPrint(&b, "0x{X}", .{2863311530}),
    );

    try expectEqualStrings(
        "5a696721",
        try bufPrint(&b, "{x}", .{"Zig!"}),
    );
}
