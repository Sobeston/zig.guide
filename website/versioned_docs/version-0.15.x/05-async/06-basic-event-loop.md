# Basic Event Loop Implementation

An event loop is a design pattern in which events are dispatched and/or waited
upon. This will mean some kind of service or runtime that resumes suspended
async frames when conditions are met. This is the most powerful and useful use
case of Zig's async.

Here we will implement a basic event loop. This one will allow us to submit
tasks to be executed in a given amount of time. We will use this to submit pairs
of tasks which will print the time since the program's start. Here is an example
of the output.

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
var timer_queue: std.PriorityQueue(Delay, void, cmp) = undefined;
fn cmp(context: void, a: Delay, b: Delay) std.math.Order {
    _ = context;
    return std.math.order(a.expires, b.expires);
}

pub fn main() !void {
    timer_queue = std.PriorityQueue(Delay, void, cmp).init(
        std.heap.page_allocator, undefined
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
