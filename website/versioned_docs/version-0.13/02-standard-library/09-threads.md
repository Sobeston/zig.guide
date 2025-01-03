# Threads

While Zig provides more advanced ways of writing concurrent and parallel code,
[`std.Thread`](https://ziglang.org/documentation/master/std/#std.Thread) is
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

## Mutexes and WaitGroups

[tp]: https://ziglang.org/documentation/0.13.0/std/#std.Thread.Pool
[wg]: https://ziglang.org/documentation/0.13.0/std/#std.Thread.WaitGroup
[mx]: https://ziglang.org/documentation/0.13.0/std/#std.Thread.Mutex
[tsa]: https://ziglang.org/documentation/0.13.0/std/#std.heap.ThreadSafeAllocator

After starting multiple threads, our main thread may need to know when all are finished; in this case we can use a _thread pool_ which, together with a _wait group_ element, allows the spawned threads to declare when they are started and finished working, as well as allowing the main thread to wait for all to have finished working. The [`std.Thread.WaitGroup`][wg] instance is passed to each threaded function to allow it to declare its state; the [`std.Thread.Pool`][tp] receives the `WaitGroup` as an element to wait on.

The `Pool` needs to be initialized with an thread safe allocator, one which can allocate memory with awareness of threading. We create a basic allocator (General Purpose, Arena, Heap, etc), and then wrap it in a [`std.heap.ThreadSafeAllocator`][tsa] to provide this safety for us. This thread-safe allocator can now be passed into any threaded functions.

When different threads try to access a shared variable simultaneously, a race condition can occur where the value is improperly stored to memory. This is a case of thread-unsafe behaviour. To provide thread safety for our own code, we must use a mutually exclusive lock, a _mutex_, provided as [`std.Thread.Mutex`][mx]. This allows different threads to work together on a same piece of data in memory without clashing. When two threads coordinate on the same mutex, they can know to wait to acquire the lock before modifying a target resource.

With these concepts together, we can write the following example program which allows each thread to update a line counter, and print a message. Note that neither thread can attempt to update the counter until the other has finished with accessing it, due to the encapsulation in a mutex, which is declared at the start of the accessing block via `.lock()`, and whose release via `.unlock()` is deferred to the end to guarantee its execution. Similarly, the `WaitGroup` is also declared at start of block, and guaranteed to release with `.finished()` at end of block via a `defer`.

```zig
const std = @import("std");
const Thread = std.Thread;

var line_counter:u8 = 0;

fn ticker(name:[]const u8, steps:u8, mut:*Thread.Mutex, wg:*Thread.WaitGroup) void {
    var i:u8 = 0;

    wg.start();
    defer wg.finish();

    while (i < steps) {
        std.time.sleep(1 * std.time.ns_per_s);

        {
            // We use a block to scope the start and end of the locking of the mutex,
            //  and do all operations that need to be done "together" in one go.
            // Note: avoid using "blocking" operations (e.g. io) or lengthy operations
            //  within a lock.
            mut.lock();
            defer mut.unlock();

            line_counter += 1;
            i += 1;
            std.debug.print("{d} {s}\n", .{line_counter, name});
        }
    }
}

pub fn main() !void {

    // ----- Memory
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // ----- Thread safety wrapping
    var tsafe_allocator: std.heap.ThreadSafeAllocator = .{
        .child_allocator = gpa.allocator(),
    };
    const alloc = tsafe_allocator.allocator();

    // To wait on threads we need a waitgroup, and a thread pool
    //   to wrap the waitgroup.
    var wg:Thread.WaitGroup = undefined;
    wg.reset();

    var pool:Thread.Pool = undefined;
    try pool.init(.{.allocator = alloc});
    defer pool.deinit();

    // A mutex to ensure we don't write the counter simultaneously
    var mut:Thread.Mutex = undefined;

    // Use OS Thread spawning, pass in a function, and the arguments to pass
    //   down to it in an anonymous struct
    _ = try std.Thread.spawn(.{}, ticker, .{"One", 1, &mut, &wg});
    _ = try std.Thread.spawn(.{}, ticker, .{"Two", 2, &mut, &wg});

    // Wait a little for a thread to call .start() - sometimes we get to the waitgroup
    //   here and see it empty... before any thread acquires it ...!!
    std.time.sleep(1 * std.time.ns_per_s);
    pool.waitAndWork(&wg);

    std.debug.print("Finished.\n", .{});
}
```
