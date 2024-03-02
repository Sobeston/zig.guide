---
pagination_prev: working-with-c/zig-cc
---

# Introduction

:::danger

Zig's async features have regressed in the compiler and are not present in the 0.11
Zig release, and they will likely not be featured in Zig 0.12 either.

:::

A functioning understanding of Zig's async requires familiarity with the concept
of the call stack. If you have not heard of this before,
[check out the wikipedia page](https://en.wikipedia.org/wiki/Call_stack).

<!-- TODO: actually explain the call stack? -->

A traditional function call comprises of three things:

1. Initiate the called function with its arguments, pushing the function's stack
   frame
2. Transfer control to the function
3. Upon function completion, hand control back to the caller, retrieving the
   function's return value and popping the function's stack frame

With Zig's async functions we can do more than this, with the transfer of
control being an ongoing two-way conversation (i.e. we can give control to the
function and take it back multiple times). Because of this, special
considerations must be made when calling a function in an async context; we can
no longer push and pop the stack frame as normal (as the stack is volatile, and
things "above" the current stack frame may be overwritten), instead explicitly
storing the async function's frame. While most people won't make use of its full
feature set, this style of async is useful for creating more powerful constructs
such as event loops.

The style of Zig's async may be described as suspendible stackless coroutines.
Zig's async is very different to something like an OS thread which has a stack,
and can only be suspended by the kernel. Furthermore, Zig's async is there to
provide you with control flow structures and code generation; async does not
imply parallelism or the usage of threads.
