// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
const test_allocator = std.testing.allocator;
// hide-end
test "stack" {
    const string = "(()())";
    var stack: std.ArrayList(usize) = .empty;
    defer stack.deinit(test_allocator);

    const Pair = struct { open: usize, close: usize };
    var pairs: std.ArrayList(Pair) = .empty;
    defer pairs.deinit(test_allocator);

    for (string, 0..) |char, i| {
        if (char == '(') try stack.append(test_allocator, i);
        if (char == ')')
            try pairs.append(test_allocator, .{
                .open = stack.pop() orelse
                    @panic("mismatched brackets"),
                .close = i,
            });
    }

    const expected_pairs: []const Pair = &.{
        .{ .open = 1, .close = 2 },
        .{ .open = 3, .close = 4 },
        .{ .open = 0, .close = 5 },
    };
    try std.testing.expectEqualDeep(expected_pairs, pairs.items);
}
