// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expectEqualStrings = std.testing.expectEqualStrings;
const bufPrint = std.fmt.bufPrint;
// hide-end
test "string fmt" {
    var b: [6]u8 = undefined;
    const hello: [*:0]const u8 = "hello!";

    try expectEqualStrings(
        "hello!",
        try bufPrint(&b, "{s}", .{hello}),
    );
}
