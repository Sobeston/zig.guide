// hide-start
const expect = @import("std").testing.expect;

// hide-end
test "for" {
    const vals = [_]u8{ 10, 20, 30, 40 };
    var valSum: u32 = 0;
    var indexSum: usize = 0;
    for (vals, 0..) |num, index| {
        valSum += num;
        indexSum += index;
    }
    try expect(indexSum == 6);
    try expect(valSum == 100);
}
