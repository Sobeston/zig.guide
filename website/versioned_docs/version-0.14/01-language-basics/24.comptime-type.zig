// hide-start
const expect = @import("std").testing.expect;

//hide-end
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .int = .{
            .bits = @typeInfo(T).int.bits + 1,
            .signedness = @typeInfo(T).int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}
