---
authors: sobeston
date: 2021-09-13
tags:
  - Zig 0.13.0
---

# Fahrenheit To Celsius

<meta name="fediverse:creator" content="@sobeston@hachyderm.io" />

Here we're going to walk through writing a program that takes a measurement in fahrenheit as its argument, and prints the value in celsius.

### Getting Arguments

Let's start by making a file called _fahrenheit_to_celsius.zig_. Here we'll again obtain a writer to _stdout_ like before.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
```

<!-- truncate -->

Now let's obtain our process' arguments. To get arguments in a cross-platform manner we will have to allocate memory, which in idiomatic Zig means the usage of an _allocator_. Here we'll pass in the _std.heap.page_allocator_, which is the most basic allocator that the standard library provides. This means that the _argsAlloc_ function will use this allocator when it allocates memory. This has a `try` in front of it as _memory allocation may fail_.

```zig
    const args = try std.process.argsAlloc(std.heap.page_allocator);
```

The _argsAlloc_ function, after unwrapping the error, gives us a _slice_. We can iterate over this with `for`, "capturing" the values and indexes. Let's use this to print all of the arguments.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    for (args, 0..) |arg, i| {
        try stdout.print("arg {}: {s}\n", .{ i, arg });
    }
}
```

This program will print something like this when run with `zig run fahrenheit_to_celsius.zig`.

```
arg 0: /home/sobe/.cache/zig/o/b947fb3eac70ec0595800316064d88dd/fahrenheit_to_celsius
```

For us the 0th argument is not what we want - we want the 1st argument, which is provided by the user. There are two ways we can provide our program more arguments. The first is via `build-exe`.

```
zig build-exe fahrenheit_to_celsius.zig
./fahrenheit_to_celsius first_argument second_argument ...
# windows: .\fahrenheit_to_celsius first_argument second_argument ...
```

We can also pass in arguments with `zig run` as follows.

```
zig run fahrenheit_to_celsius.zig -- first_argument second_argument ...
```

Let's have our program skip the 0th argument, and make sure that there's a first argument.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    const args = try std.process.argsAlloc(std.heap.page_allocator);

    if (args.len < 2) return error.ExpectedArgument;

    for (args, 0..) |arg, i| {
        if (i == 0) continue;
        try stdout.print("arg {}: {s}\n", .{ i, arg });
    }
}
```

Finally, now that we've gotten the arguments, we should deallocate the memory that we allocated in order to obtain the arguments. Here we're introducing the `defer` statement. What follows a defer statement will be executed when the current function is returned from. The usage here means that we can be sure our args' memory is freed when main is returned from.

```zig
    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);
```

### Performing Conversion

Now that we know how to get the process' arguments, let's start performing the conversion. Let's start from here.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) return error.ExpectedArgument;
```

The first step is to turn our argument string into a float. The standard library contains such a utility, where the first argument is the type of float returned. This function fails if it is provided a string which cannot be turned into a float.

```zig
    const f = try std.fmt.parseFloat(f32, args[1]);
```

We can convert this to celsius as follows.

```zig
    const c = (f - 32) * (5.0 / 9.0);
```

And now we can print the value.

```zig
    try stdout.print("{}c\n", .{c});
```

However this will give us an ugly output, as the default float formatting gives us scientific form.

```
$ zig run fahrenheit_to_celsius.zig -- 100
3.77777786e+01c
```

By changing the _format specifier_ from `{}` to `{d}`, we can print in decimal form. We can also reduce the precision of the output by using `{d:.x}`, where _x_ is the amount of decimal places.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const args = try std.process.argsAlloc(std.heap.page_allocator);
    defer std.process.argsFree(std.heap.page_allocator, args);

    if (args.len < 2) return error.ExpectedArgument;

    const f = try std.fmt.parseFloat(f32, args[1]);
    const c = (f - 32) * (5.0 / 9.0);
    try stdout.print("{d:.1}c\n", .{c});
}
```

This yields a much more friendly output.

```
zig run fahrenheit_to_celsius.zig -- 100
37.8c
```
