// Used for testing. To be manually kept in sync with accompanying markdown file.

const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    if (args.len < 2) return error.ExpectedArgument;

    for (args, 0..) |arg, i| {
        if (i == 0) continue;
        try stdout.print("arg {}: {s}\n", .{ i, arg });
    }
}

test {
    std.testing.refAllDecls(@This());
}
