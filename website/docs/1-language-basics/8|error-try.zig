// hide-start
const expect = @import("std").testing.expect;

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

//hide-end
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}
