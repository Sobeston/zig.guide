// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "@intCast" {
    const x: u64 = 200;
    const y = @as(u8, @intCast(x));
    try expect(@TypeOf(y) == u8);
}
