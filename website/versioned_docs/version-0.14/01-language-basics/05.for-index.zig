// hide-start
const expect = @import("std").testing.expect;

// hide-end
test "for" {
    const vals = [4]u8{ 10, 20, 30, 40 };
    var val_sum: u32 = 0;
    var index_sum: usize = 0;
    for (vals, 0..) |num, index| {
        val_sum += num;
        index_sum += index;
    }
    try expect(index_sum == 6);
    try expect(val_sum == 100);
}
