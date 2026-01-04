// Used for testing. To be manually kept in sync with accompanying markdown file.

const std = @import("std");

pub fn main() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    var prng: std.Random.DefaultPrng = .init(seed);
    const rand = prng.random();

    const target_number = rand.intRangeAtMost(u8, 1, 100);

    var stdin_buf: [1024]u8 = undefined;
    var stdout_buf: [1024]u8 = undefined;

    while (true) {
        var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
        const stdin = &stdin_reader.interface;

        var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
        const stdout = &stdout_writer.interface;
        defer stdout.flush() catch {};

        const line = try stdin.takeDelimiterExclusive('\n');

        const guess = std.fmt.parseInt(u8, line, 10) catch |err| {
            const err_string = switch (err) {
                error.Overflow => "Please enter a small positive number\n",
                error.InvalidCharacter => "Please enter a valid number\n",
            };
            try stdout.writeAll(err_string);
            continue;
        };

        if (guess < target_number) try stdout.writeAll("Too Small!\n");
        if (guess > target_number) try stdout.writeAll("Too Big!\n");
        if (guess == target_number) {
            try stdout.writeAll("Correct!\n");
            break;
        }
    }
}

test {
    std.testing.refAllDecls(@This());
}
