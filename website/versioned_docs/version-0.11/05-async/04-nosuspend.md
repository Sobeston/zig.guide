# Nosuspend

When calling a function which is determined to be async (i.e. it may suspend)
without an `async` invocation, the function which called it is also treated as
being async. When a function of a concrete (non-async) calling convention is
determined to have suspend points, this is a compile error as async requires its
own calling convention. This means, for example, that main cannot be async.

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

If you want to call an async function without using an `async` invocation, and
without the caller of the function also being async, the `nosuspend` keyword
comes in handy. This allows the caller of the async function to not also be
async, by asserting that the potential suspends do not happen.

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

In the above code if we change the value of `ticker` to be above 0, this is
detectable illegal behaviour. If we run that code, we will have an error like
this in safe build modes. Similar to other illegal behaviours in Zig, having
these happen in unsafe modes will result in undefined behaviour.

```
async function called in nosuspend scope suspended
.\main.zig:16:47: 0x7ff661dd3414 in main (main.obj)
    const duration = nosuspend doTicksDuration(&ticker);
                                              ^
C:\zig\lib\zig\std\start.zig:173:65: 0x7ff661dd18ce in std.start.WinStartup (main.obj)
    std.os.windows.kernel32.ExitProcess(initEventLoopAndCallMain());
                                                                ^
```
