---
title: "Chapter 5 - Async"
weight: 5
date: 2020-10-04 18:02:00
description: "Chapter 5 - Learn about how the ziglang's async works"
---

Zig provides low level constructs for making use of stackless coroutines. Zig's async functions are [colorless](https://journal.stuffwithstuff.com/2015/02/01/what-color-is-your-function/), and make use of their own calling convention.

# Suspend Resume

Async functions may suspend themselves at any point, which causes control flow to return to the call site (in the case of the first suspension) or the resumer (in the case of subsequent suspensions). Each `suspend` should have a corresponding `resume`.

Without a `resume`, this function never completes its execution. In the following examples, the order of execution has been written via comments to aid your understanding. Note the `async func()` syntax being used - this will be explained in the next section.

```zig
const expect = @import("std").testing.expect;

var x: i32 = 1;

test "suspend with no resume" {
    var frame = async func();   //1
    expect(x == 2);             //4
}

fn func() void {
    x += 1;                     //2
    suspend;                    //3
    x += 1;                     //never reached!
}
```

A resume gives back the control flow to the function until the next suspend point or return.

```zig
var y: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    expect(y == 3);             //6
}

fn func2() void {
    y += 1;                     //2
    suspend;                    //3
    y += 1;                     //5
}
```

