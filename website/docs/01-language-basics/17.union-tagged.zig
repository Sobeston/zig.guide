// hide-start
const expect = @import("std").testing.expect;

//hide-end
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byteVal| byteVal.* += 1,
        .b => |*floatVal| floatVal.* *= 2,
        .c => |*boolVal| boolVal.* = !boolVal.*,
    }
    try expect(value.b == 3);
}
