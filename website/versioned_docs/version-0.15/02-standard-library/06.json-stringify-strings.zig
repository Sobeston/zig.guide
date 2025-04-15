// hide-start
const std = @import("std");
const expect = std.testing.expect;
const eql = std.mem.eql;
const test_allocator = std.testing.allocator;
// hide-end
test "json parse with strings" {
    const User = struct { name: []u8, age: u16 };

    const parsed = try std.json.parseFromSlice(User, test_allocator,
        \\{ "name": "Joe", "age": 25 }
    , .{});
    defer parsed.deinit();

    const user = parsed.value;

    try expect(eql(u8, user.name, "Joe"));
    try expect(user.age == 25);
}
