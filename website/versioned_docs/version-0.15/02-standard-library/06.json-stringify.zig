// hide-start
const std = @import("std");
// hide-end
const Place = struct { lat: f32, long: f32 };

test "json stringify" {
    const x = Place{
        .lat = 51.997664,
        .long = -0.740687,
    };

    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const jsonStr = try std.json.Stringify.valueAlloc(fba.allocator(), x, .{});

    try std.testing.expectEqualSlices(u8,
        \\{"lat":51.99766540527344,"long":-0.7406870126724243}
    , jsonStr);
}
