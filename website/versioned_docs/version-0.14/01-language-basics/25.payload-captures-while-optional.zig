// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "while optional" {
    const sequence = [_]?u8{ 0xFF, 0xCC, 0x00, null };

    var i: usize = 0;
    while (sequence[i]) |num| : (i += 1) {
        try expect(@TypeOf(num) == u8);
    }

    try expect(i == 3);
    try expect(sequence[i] == null);
}
