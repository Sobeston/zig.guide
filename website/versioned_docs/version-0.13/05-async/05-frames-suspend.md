# Async Frames, Suspend Blocks

`@Frame(function)` returns the frame type of the function. This works for async
functions, and functions without a specific calling convention.

```zig
fn add(a: i32, b: i32) i64 {
    return a + b;
}

test "@Frame" {
    var frame: @Frame(add) = async add(1, 2);
    try expect(await frame == 3);
}
```

[`@frame()`](https://ziglang.org/documentation/master/#frame) returns a pointer
to the frame of the current function. Similar to `suspend` points, if this call
is found in a function then it is inferred as being async. All pointers to
frames coerce to the special type `anyframe`, which you can use `resume` upon.

This allows us to, for example, write a function that resumes itself.

```zig
fn double(value: u8) u9 {
    suspend {
        resume @frame();
    }
    return value * 2;
}

test "@frame 1" {
    var f = async double(1);
    try expect(nosuspend await f == 2);
}
```

Or, more interestingly, we can use it to tell other functions to resume us. Here
we're introducing **suspend blocks**. Upon entering a suspend block, the async
function is already considered suspended (i.e. it can be resumed). This means
that we can have our function resumed by something other than the last resumer.

```zig
const std = @import("std");

fn callLater(comptime laterFn: fn () void, ms: u64) void {
    suspend {
        wakeupLater(@frame(), ms);
    }
    laterFn();
}

fn wakeupLater(frame: anyframe, ms: u64) void {
    std.time.sleep(ms * std.time.ns_per_ms);
    resume frame;
}

fn alarm() void {
    std.debug.print("Time's Up!\n", .{});
}

test "@frame 2" {
    nosuspend callLater(alarm, 1000);
}
```

Using the `anyframe` data type can be thought of as a kind of type erasure, in
that we are no longer sure of the concrete type of the function or the function
frame. This is useful as it still allows us to resume the frame - in a lot of
code we will not care about the details and will just want to resume it. This
gives us a single concrete type which we can use for our async logic.

The natural drawback of `anyframe` is that we have lost type information, and we
no longer know what the return type of the function is. This means we cannot
await an `anyframe`. Zig's solution to this is the `anyframe->T` types, where
the `T` is the return type of the frame.

```zig
fn zero(comptime x: anytype) x {
    return 0;
}

fn awaiter(x: anyframe->f32) f32 {
    return nosuspend await x;
}

test "anyframe->T" {
    var frame = async zero(f32);
    try expect(awaiter(&frame) == 0);
}
```
