# Threads

While Zig provides more advanced ways of writing concurrent and parallel code,
[`std.Thread`](https://ziglang.org/documentation/master/std/#A;std:Thread) is
available for making use of OS threads. Let's make use of an OS thread.

```zig
fn ticker(step: u8) void {
    while (true) {
        std.time.sleep(1 * std.time.ns_per_s);
        tick += @as(isize, step);
    }
}

var tick: isize = 0;

test "threading" {
    var thread = try std.Thread.spawn(.{}, ticker, .{@as(u8, 1)});
    _ = thread;
    try expect(tick == 0);
    std.time.sleep(3 * std.time.ns_per_s / 2);
    try expect(tick == 1);
}
```

Threads, however, aren't particularly useful without strategies for thread
safety.
