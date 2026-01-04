// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "optional-if" {
    const maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}
