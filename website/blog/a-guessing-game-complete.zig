// Used for testing. To be manually kept in sync with accompanying markdown file.

const std = @import("std");

pub fn main() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    var prng: std.Random.DefaultPrng = .init(seed);
    const rand = prng.random();

    const target_number = rand.intRangeAtMost(u8, 1, 100);

    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    while (true) {
        defer stdout.flush() catch {};

        const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
        const line = std.mem.trim(u8, bare_line, "\r");

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
