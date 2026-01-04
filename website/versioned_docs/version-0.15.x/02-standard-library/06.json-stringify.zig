// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const test_allocator = std.testing.allocator;
const Place = struct { lat: f32, long: f32 };
// hide-end
test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var string: std.io.Writer.Allocating = .init(test_allocator);
    defer string.deinit();

    try string.writer.print("{f}", .{std.json.fmt(x, .{})});

    try std.testing.expectEqualStrings(
        \\{"lat":51.99766540527344,"long":-0.7406870126724243}
    , string.written());
}
