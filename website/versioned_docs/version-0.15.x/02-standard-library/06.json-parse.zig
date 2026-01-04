// hide-start
const std = @import("std");
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
// hide-end
const Place = struct { lat: f32, long: f32 };

test "json parse" {
    const parsed = try std.json.parseFromSlice(
        Place,
        test_allocator,
        \\{ "lat": 40.684540, "long": -74.401422 }
    ,
        .{},
    );
    defer parsed.deinit();

    const place = parsed.value;

    try expect(place.lat == 40.684540);
    try expect(place.long == -74.401422);
}
