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
    var buf: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const jsonStr = try std.json.stringifyAlloc(fba.allocator(), x, .{});

    try expect(eql(u8, jsonStr,
        \\{"lat":5.199766540527344e1,"long":-7.406870126724243e-1}
    ));
}
