# Calling conventions

Calling conventions describe how functions are called. This includes how
arguments are supplied to the function (i.e. where they go - in registers or on
the stack, and how), and how the return value is received.

In Zig, the attribute `callconv` may be given to a function. The calling
conventions available may be found in
[std.builtin.CallingConvention](https://ziglang.org/documentation/master/std/#A;std:builtin.CallingConvention).
Here we make use of the cdecl calling convention.

```zig
fn add(a: u32, b: u32) callconv(.C) u32 {
    return a + b;
}
```

Marking your functions with the C calling convention is crucial when you're
calling Zig from C.
