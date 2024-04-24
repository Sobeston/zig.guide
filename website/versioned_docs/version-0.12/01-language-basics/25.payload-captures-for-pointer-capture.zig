// hide-start
const expect = @import("std").testing.expect;
const eql = @import("std").mem.eql;

//hide-end
test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
