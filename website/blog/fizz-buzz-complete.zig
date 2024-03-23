// Used for testing. To be manually kept in sync with accompanying markdown file.

const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var count: u8 = 1;

    while (count <= 100) : (count += 1) {
        const div_3: u2 = @intFromBool(count % 3 == 0);
        const div_5 = @intFromBool(count % 5 == 0);

        switch (div_3 * 2 + div_5) {
            0b10 => try stdout.writeAll("Fizz\n"),
            0b11 => try stdout.writeAll("Fizz Buzz\n"),
            0b01 => try stdout.writeAll("Buzz\n"),
            0b00 => try stdout.print("{}\n", .{count}),
        }
    }
}

test {
    std.testing.refAllDecls(@This());
}
