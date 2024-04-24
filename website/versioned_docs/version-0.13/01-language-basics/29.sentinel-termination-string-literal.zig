// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "string literal" {
    try expect(@TypeOf("hello") == *const [5:0]u8);
}
