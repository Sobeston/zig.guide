// hide-start
const expect = @import("std").testing.expect;

// hide-end
test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
    try expect(i == 11);
}
