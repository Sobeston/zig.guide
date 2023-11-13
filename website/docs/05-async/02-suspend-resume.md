# Suspend / Resume

In the previous section we talked of how async functions can give control back
to the caller, and how the async function can later take control back. This
functionality is provided by the keywords
[`suspend`, and `resume`](https://ziglang.org/documentation/master/#Suspend-and-Resume).
When a function suspends, control flow returns to wherever it was last resumed;
when a function is called via an `async` invocation, this is an implicit resume.

The comments in these examples indicate the order of execution. There are a few
things to take in here:

- The `async` keyword is used to invoke functions in an async context.
- `async func()` returns the function's frame.
- We must store this frame.
- The `resume` keyword is used on the frame, whereas `suspend` is used from the
  called function.

This example has a suspend, but no matching resume.

```zig
const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func(); //1
    _ = frame;
    try expect(foo == 2);     //4
}

fn func() void {
    foo += 1;                 //2
    suspend {}                //3
    foo += 1;                 //never reached!
}
```

In well formed code, each suspend is matched with a resume.

```zig
var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    try expect(bar == 3);       //6
}

fn func2() void {
    bar += 1;                   //2
    suspend {}                  //3
    bar += 1;                   //5
}
```
