// hide-start
const expect = @import("std").testing.expect;

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

//hide-end
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
