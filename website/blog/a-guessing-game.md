---
authors: sobeston
date: 2021-09-13
tags:
  - Zig 0.15.x
---

# A Guessing Game

<meta name="fediverse:creator" content="@sobeston@hachyderm.io" />

We are going to make a program that randomly picks a number from 1 to 100 and asks us to guess it, telling us if our number is too big or too small.

### Getting a Random Number

As Zig does not have a runtime, it does not manage a PRNG (pseudorandom number generator) for us. This means that we'll have to create our PRNG and initialise it with a source of entropy. Let's start with a file called _a_guessing_game.zig_.

<!-- truncate -->

```zig
const std = @import("std");

pub fn main() !void {
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

```

Let's initialise _std.rand.DefaultPrng_ with a 64 bit unsigned integer (`u64`). Our `rand` here allows us to access many useful utilities for our PRNG. Here we're asking our PRNG for a random number from 1 to 100, however, if our PRNG is initialised with the same number every time our program will always print out the same number.

```zig
    var prng: std.Random.DefaultPrng = .init(seed);(1625953);
    const rand = prng.random();

    try stdout.print(
        "not-so random number: {}\n",
        .{rand.intRangeAtMost(u8, 1, 100)},
    );
```

For a good source of entropy, it is best to initialise our PRNG with random bytes provided by the OS. Let's ask the OS for some. As Zig doesn't let us declare a variable without a value we've had to give our seed variable the value of `undefined`, which is a special value that coerces to any type. The function _std.posix.getrandom_ takes in a _slice_ of bytes, where a slice is a pointer to a buffer whose length is known at runtime. Because of this we've used _std.mem.asBytes_ to turn our pointer to a `u64` into a slice of bytes. If _getrandom_ succeeds it will fill our seed variable with a random value which we can then initialise the PRNG with.

```zig
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    var prng: std.Random.DefaultPrng = .init(seed);(seed);
    const rand = prng.random();
```

### Taking User Input

Let's start here, where our program already has a random secret value which we must guess.

```zig
const std = @import("std");

pub fn main() !void {
    var seed: u64 = undefined;
    try std.posix.getrandom(std.mem.asBytes(&seed));

    var prng: std.Random.DefaultPrng = .init(seed);(seed);
    const rand = prng.random();

    const target_number = rand.intRangeAtMost(u8, 1, 100);

```

As we'll be printing and taking in user input until the correct value is guessed, let's start by making a while loop with `stdin` and `stdout`. Note how we've obtained an `stdin` _reader_.

```zig
    var stdout_buf: [1024]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buf);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stdin_buf: [1024]u8 = undefined;
    var stdin_reader = std.fs.File.stdin().reader(&stdin_buf);
    const stdin: *std.io.Reader = &stdin_reader.interface;

    while (true) {
        defer stdout.flush() catch {};
```

To get a line of user's input, we have to read `stdin` until we encounter a newline character, which is represented by `\n`. What is read will be copied into the buffer
of our reader.

```zig
        const bare_line = try stdin.takeDelimiter('\n') orelse unreachable;
```

Because of legacy reasons newlines in many places in Windows are represented by the two-character sequence `\r\n`, which means that we must strip `\r` from the line that we've read. Without this our program will behave incorrectly on Windows.

```zig
        const line = std.mem.trim(u8, bare_line, "\r");
```

### Guessing

Let's continue from here. We're expecting the user to input an integer number here, so the next step is to parse a number from `line`.

```zig
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
```

This can be achieved by passing the buffer to _std.fmt.parseInt_, where the last parameter is the base of the number in the string. So far we've only handled errors with `try`, which returns the error if encountered, but here we'll want to `catch` the error so that we can process it without returning it. If there's an error we'll print a friendly error message and `continue`, so that the user can re-enter their number.

```zig
        const guess = std.fmt.parseInt(u8, line, 10) catch |err| {
            const err_string = switch (err) {
                error.Overflow => "Please enter a small positive number\n",
                error.InvalidCharacter => "Please enter a valid number\n",
            };
            try stdout.writeAll(err_string);
            continue;
        };
```

Now all we have to do is decide what to do with the user's guess. It's important to leave the loop using `break` when the user makes a correct guess.

```zig
        if (guess < target_number) try stdout.writeAll("Too Small!\n");
        if (guess > target_number) try stdout.writeAll("Too Big!\n");
        if (guess == target_number) {
            try stdout.writeAll("Correct!\n");
            break;
        }
```

Let's try playing our game.

```console
$ zig run a_guessing_game.zig
45
Too Big!
20
Too Small!
25
Too Small!
32
Too Small!
38
Too Small!
41
Too Small!
43
Too Small!
44
Correct!
```
