// hide-start
const expect = @import("std").testing.expect;

// hide-end
test "for loop with multiple iterables" {
    var sum: i32 = 0;
    const digits = [4]i32{ 7, 3, 4, 9 };
    const places = [4]i32{ 1, 10, 100, 1000 };
    for (digits, places) |digit, place| {
        sum += digit * place;
    }
    try expect(sum == 9437);
}
