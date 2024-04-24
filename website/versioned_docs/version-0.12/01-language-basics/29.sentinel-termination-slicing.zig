// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "sentinel terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3 :0];
    _ = y;
}
