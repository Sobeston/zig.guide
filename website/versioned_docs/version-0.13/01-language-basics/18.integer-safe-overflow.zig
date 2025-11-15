// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}
