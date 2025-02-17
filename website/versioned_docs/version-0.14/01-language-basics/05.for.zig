// hide-start
const expect = @import("std").testing.expect;

// hide-end
test "for" {
    const vals = [_]u8{ 2, 3, 4 };
    var sum: u8 = 0;
    // num is the captured value on each iteration of the loop.
    for (vals) |num| {
        sum += num;
    }
    try expect(sum == 9);
}

test "for-with-continue" {
    const vals = [_]u8{ 2, 3, 0, 4 };
    var product: u32 = 1;
    for (vals) |num| {
        if (num == 0) continue;
        product *= num;
    }
    try expect(product == 24);
}
