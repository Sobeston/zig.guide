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

    var buf: [100]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var string = std.ArrayList(u8).init(fba.allocator());
    try std.json.stringify(x, .{}, string.writer());

    try expect(eql(u8, string.items,
        \\{"lat":5.199766540527344e1,"long":-7.406870126724243e-1}
    ));
}
