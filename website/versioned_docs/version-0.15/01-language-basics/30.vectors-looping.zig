// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "vector looping" {
    const x = @Vector(4, u8){ 255, 0, 255, 0 };
    const sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < 4) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
