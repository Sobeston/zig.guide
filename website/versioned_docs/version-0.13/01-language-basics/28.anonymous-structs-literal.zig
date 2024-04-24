// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    const pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}
