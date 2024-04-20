import CodeBlock from "@theme/CodeBlock";

import SwitchUnreachable from "!!raw-loader!./10.switch-unreachable.zig";

# Runtime Safety

Zig provides a level of safety, where problems may be found during execution.
Safety can be left on, or turned off. Zig has many cases of so-called
**detectable illegal behaviour**, meaning that illegal behaviour will be caught
(causing a panic) with safety on, but will result in undefined behaviour with
safety off. Users are strongly recommended to develop and test their software
with safety on, despite its speed penalties.

For example, runtime safety protects you from out of bounds indices.

```zig
test "out of bounds" {
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
```

```
test "out of bounds"...index out of bounds
.\tests.zig:43:14: 0x7ff698cc1b82 in test "out of bounds" (test.obj)
    const b = a[index];
             ^
```

The user may disable runtime safety for the current block using the built-in
function
[`@setRuntimeSafety`](https://ziglang.org/documentation/master/#setRuntimeSafety).

```zig
test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
    _ = b;
}
```

Safety is off for some build modes (to be discussed later).

# Unreachable

[`unreachable`](https://ziglang.org/documentation/master/#unreachable) is an
assertion to the compiler that this statement will not be reached. It can tell
the compiler that a branch is impossible, which the optimiser can then take
advantage of. Reaching an
[`unreachable`](https://ziglang.org/documentation/master/#unreachable) is
detectable illegal behaviour.

As it is of the type
[`noreturn`](https://ziglang.org/documentation/master/#noreturn), it is
compatible with all other types. Here it coerces to u32.

```zig
test "unreachable" {
    const x: i32 = 1;
    const y: u32 = if (x == 2) 5 else unreachable;
    _ = y;
}
```

```
test "unreachable"...reached unreachable code
.\tests.zig:211:39: 0x7ff7e29b2049 in test "unreachable" (test.obj)
    const y: u32 = if (x == 2) 5 else unreachable;
                                      ^
```

Here is an unreachable being used in a switch.

<CodeBlock language="zig">{SwitchUnreachable}</CodeBlock>
