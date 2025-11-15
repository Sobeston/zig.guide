// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "vector indexing" {
    const x: @Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[0] == 255);
}
