---
title: "Chapter 5 - Async"
weight: 6
date: 2021-01-08 01:39:00
description: "Chapter 5 - Learn about how the ziglang's async works"
---

# Async

A functioning understanding of Zig's async requires familiarity with the concept of the call stack. If you have not heard of this before, [check out the wikipedia page](https://en.wikipedia.org/wiki/Call_stack).

<!-- TODO: actually explain the call stack? -->

A traditional function call comprises of three things:
1. Initiate the called function with its arguments, pushing the function's stack frame
2. Transfer control to the function
3. Upon function completion, hand control back to the caller, retrieving the function's return value and popping the function's stack frame

With Zig's async functions we can do more than this, with the transfer of control being an ongoing two-way conversation (i.e. we can give control to the function and take it back multiple times). Because of this, special considerations must be made when calling a function in an async context; we can no longer push and pop the stack frame as normal (as the stack is volatile, and things "above" the current stack frame may be overwritten), instead explicitly storing the async function's frame. While most people won't make use of its full feature set, this style of async is useful for creating more powerful constructs such as event loops.

The style of Zig's async may be described as suspendible stackless coroutines. Zig's async is very different to something like an OS thread which has a stack, and can only be suspended by the kernel. Furthermore, Zig's async is there to provide you with control flow structures and code generation; async does not imply parallelism or the usage of threads.

# Suspend / Resume

In the previous section we talked of how async functions can give control back to the caller, and how the async function can later take control back. This functionality is provided by the keywords [`suspend`, and `resume`](https://ziglang.org/documentation/master/#Suspend-and-Resume). When a function suspends, control flow returns to wherever it was last resumed; when a function is called via an `async` invocation, this is an implicit resume.

The comments in these examples indicate the order of execution. There are a few things to take in here:
*  The `async` keyword is used to invoke functions in an async context.
*  `async func()` returns the function's frame.
*  We must store this frame.
*  The `resume` keyword is used on the frame, whereas `suspend` is used from the called function.

This example has a suspend, but no matching resume.
```zig
const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func();   //1
    try expect(foo == 2);           //4
}

fn func() void {
    foo += 1;                   //2
    suspend {}                    //3
    foo += 1;                   //never reached!
}
```

In well formed code, each suspend is matched with a resume.

```zig
var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    try expect(bar == 3);           //6
}

fn func2() void {
    bar += 1;                   //2
    suspend {}                    //3
    bar += 1;                   //5
}
```

# Async / Await

Similar to how well formed code has a suspend for every resume, each `async` function invocation with a return value must be matched with an `await`. The value yielded by `await` on the async frame corresponds to the function's return.

You may notice that `func3` here is a normal function (i.e. it has no suspend points - it is not an async function). Despite this, `func3` can work as an async function when called from an async invocation; the calling convention of `func3` doesn't have to be changed to async - `func3` can be of any calling convention.

```zig
fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}
```

Using `await` on an async frame of a function which may suspend is only possible from async functions. As such, functions that use `await` on the frame of an async function are also considered async functions. If you can be sure that the potential suspend doesn't happen, `nosuspend await` will stop this from happening.

# Nosuspend

When calling a function which is determined to be async (i.e. it may suspend) without an `async` invocation, the function which called it is also treated as being async. When a function of a concrete (non-async) calling convention is determined to have suspend points, this is a compile error as async requires its own calling convention. This means, for example, that main cannot be async.

<!--no_test-->
```zig
pub fn main() !void {
    suspend {}
}
```
(compiled from windows)
```
C:\zig\lib\zig\std\start.zig:165:1: error: function with calling convention 'Stdcall' cannot be async
fn WinStartup() callconv(.Stdcall) noreturn {
^
C:\zig\lib\zig\std\start.zig:173:65: note: async function call here
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
C:\zig\lib\zig\std\start.zig:276:12: note: async function call here
    return @call(.{ .modifier = .always_inline }, callMain, .{});
           ^
C:\zig\lib\zig\std\start.zig:334:37: note: async function call here
            const result = root.main() catch |err| {
                                    ^
.\main.zig:12:5: note: suspends here
    suspend {}
    ^
```

If you want to call an async function without using an `async` invocation, and without the caller of the function also being async, the `nosuspend` keyword comes in handy. This allows the caller of the async function to not also be async, by asserting that the potential suspends do not happen.

<!--no_test-->
```zig
const std = @import("std");

fn doTicksDuration(ticker: *u32) i64 {
    const start = std.time.milliTimestamp();

    while (ticker.* > 0) {
        suspend {}
        ticker.* -= 1;
    }

    return std.time.milliTimestamp() - start;
}

pub fn main() !void {
    var ticker: u32 = 0;
    const duration = nosuspend doTicksDuration(&ticker);
}
```

In the above code if we change the value of `ticker` to be above 0, this is detectable illegal behaviour. If we run that code, we will have an error like this in safe build modes. Similar to other illegal behaviours in Zig, having these happen in unsafe modes will result in undefined behaviour.

```
async function called in nosuspend scope suspended
.\main.zig:16:47: 0x7ff661dd3414 in main (main.obj)
    const duration = nosuspend doTicksDuration(&ticker);
                                              ^
C:\zig\lib\zig\std\start.zig:173:65: 0x7ff661dd18ce in std.start.WinStartup (main.obj)
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
```

# Async Frames, Suspend Blocks

`@Frame(function)` returns the frame type of the function. This works for async functions, and functions without a specific calling convention.

```zig
fn add(a: i32, b: i32) i64 {
    return a + b;
}

test "@Frame" {
    var frame: @Frame(add) = async add(1, 2);
    try expect(await frame == 3);
}
```

[`@frame()`](https://ziglang.org/documentation/master/#Frame) returns a pointer to the frame of the current function. Similar to `suspend` points, if this call is found in a function then it is inferred as being async. All pointers to frames coerce to the special type `anyframe`, which you can use `resume` upon.

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

Or, more interestingly, we can use it to tell other functions to resume us. Here we're introducing **suspend blocks**. Upon entering a suspend block, the async function is already considered suspended (i.e. it can be resumed). This means that we can have our function resumed by something other than the last resumer.

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

Using the `anyframe` data type can be thought of as a kind of type erasure, in that we are no longer sure of the concrete type of the function or the function frame. This is useful as it still allows us to resume the frame - in a lot of code we will not care about the details and will just want to resume it. This gives us a single concrete type which we can use for our async logic.

The natural drawback of `anyframe` is that we have lost type information, and we no longer know what the return type of the function is. This means we cannot await an `anyframe`. Zig's solution to this is the `anyframe->T` types, where the `T` is the return type of the frame.

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

# Basic Event Loop Implementation

An event loop is a design pattern in which events are dispatched and/or waited upon. This will mean some kind of service or runtime that resumes suspended async frames when conditions are met. This is the most powerful and useful use case of Zig's async.

Here we will implement a basic event loop. This one will allow us to submit tasks to be executed in a given amount of time. We will use this to submit pairs of tasks which will print the time since the program's start. Here is an example of the output.

```
[task-pair b] it is now 499 ms since start!
[task-pair a] it is now 1000 ms since start!
[task-pair b] it is now 1819 ms since start!
[task-pair a] it is now 2201 ms since start!
```

Here is the implementation.

<!--no_test-->
```zig
const std = @import("std");

// used to get monotonic time, as opposed to wall-clock time
var timer: ?std.time.Timer = null;
fn nanotime() u64 {
    if (timer == null) {
        timer = std.time.Timer.start() catch unreachable;
    }
    return timer.?.read();
}

// holds the frame, and the nanotime of
// when the frame should be resumed
const Delay = struct {
    frame: anyframe,
    expires: u64,
};

// suspend the caller, to be resumed later by the event loop
fn waitForTime(time_ms: u64) void {
    suspend timer_queue.add(Delay{
        .frame = @frame(),
        .expires = nanotime() + (time_ms * std.time.ns_per_ms),
    }) catch unreachable;
}

fn waitUntilAndPrint(
    time1: u64,
    time2: u64,
    name: []const u8,
) void {
    const start = nanotime();

    // suspend self, to be woken up when time1 has passed
    waitForTime(time1);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );

    // suspend self, to be woken up when time2 has passed
    waitForTime(time2);
    std.debug.print(
        "[{s}] it is now {} ms since start!\n",
        .{ name, (nanotime() - start) / std.time.ns_per_ms },
    );
}

fn asyncMain() void {
    // stores the async frames of our tasks
    var tasks = [_]@Frame(waitUntilAndPrint){
        async waitUntilAndPrint(1000, 1200, "task-pair a"),
        async waitUntilAndPrint(500, 1300, "task-pair b"),
    };
    // |*t| is used, as |t| would be a *const @Frame(...)
    // which cannot be awaited upon
    for (tasks) |*t| await t;
}

// priority queue of tasks
// lower .expires => higher priority => to be executed before
var timer_queue: std.PriorityQueue(Delay) = undefined;
fn cmp(a: Delay, b: Delay) bool {
    return a.expires < b.expires;
}

pub fn main() !void {
    timer_queue = std.PriorityQueue(Delay).init(
        std.heap.page_allocator,
        cmp,
    );
    defer timer_queue.deinit();

    var main_task = async asyncMain();

    // the body of the event loop
    // pops the task which is to be next executed
    while (timer_queue.removeOrNull()) |delay| {
        // wait until it is time to execute next task
        const now = nanotime();
        if (now < delay.expires) {
            std.time.sleep(delay.expires - now);
        }
        // execute next task
        resume delay.frame;
    }

    nosuspend await main_task;
}
```

# End of Chapter 5

This chapter is incomplete and in future should contain usage of [`std.event.Loop`](https://ziglang.org/documentation/master/std/#std;event.Loop), and evented IO.

Feedback and PRs are welcome.
