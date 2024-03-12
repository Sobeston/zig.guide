---
authors: sobeston
date: 2021-09-13
---

# Fizz Buzz

Let's start playing with Zig by solving a problem together. 

*Fizz buzz* is a game where you count upwards from one. If the current number isn't divisible by five or three, the number is said. If the current number is divisible by three, "Fizz" is said; if the number is divisible by five, "Buzz" is said. And if the number is divisible by both three *and* five, "Fizz Buzz" is said.

### Starting

Let's make a new file called *fizz_buzz.zig* and fill it with the following code. This provides us with an entry point and a way to print to the console. For now we will take for granted that our `stdout` *writer* works.

```zig
const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

}
```

Here, `const` is used to store the value returned by *getStdOut().writer()*. We may use `var` to declare a variable instead; `const` denotes immutability. We'll want a variable that stores what number we're currently at, so let's call it count and set it to one.

```zig
    const stdout = std.io.getStdOut().writer();
    var count = 1;
```

In Zig there is no *default* integer type for your programs; what languages normally call "int" does not exist in Zig. What we've done here is made our `count` variable have the type of `comptime_int`. As the name suggests, these integers may only be manipulated at compile time which renders them useless for our uses. When working with integers in Zig you must choose the size and signedness of your integers. Here we'll make `count` an unsigned 8-bit integer, where the `u` in `u8` means unsigned, and `i` is for signed. 

```zig
    const stdout = std.io.getStdOut().writer();
    var count: u8 = 1;
```

What we'll do next is introduce a loop, from 1 to 100. This `while` loop is made up of three components: a *condition*, a *continue expression*, and a *body*, where the continue expression is what is executed upon continuing in the loop (whether via the `continue` keyword or otherwise).

```zig
    var count: u8 = 1;
    while (count <= 100) : (count += 1) {

    }
```

Here we'll print all numbers from 1 to 100 (inclusive). The first argument of `print` is a format string and the second argument is the data. Our usage of print here outputs the value of count followed by a newline.

```zig
    var count: u8 = 1;
    while (count <= 100) : (count += 1) {
        try stdout.print("{}\n", .{count});
    }
```

Now we can test `count` for being multiples of three or five, using if statements. Here we'll introduce the `%` operator, which performs modulus division between a numerator and denominator. When `a % b` equals zero, we know that `a` is a multiple of `b`.

```zig
    var count: u8 = 1;
    while (count <= 100) : (count += 1) {
        if (count % 3 == 0 and count % 5 == 0) {
            try stdout.writeAll("Fizz Buzz\n");
        } else if (count % 5 == 0) {
            try stdout.writeAll("Buzz\n");
        } else if (count % 3 == 0) {
            try stdout.writeAll("Fizz\n");
        } else {
            try stdout.print("{}\n", .{count});
        }
    }
```

> Modulus division is more complicated with a signed numerator.

### Using a Switch

We can also write this using a switch over an integer. Here we're using `@intFromBool` which converts bool values into a `u1` value (i.e. a 1 bit unsigned integer). You may notice that we haven't given `div_5` an explicit type - this is because it is inferred from the value that is assigned to it. We have however given `div_3` a type; this is as integers may *widen* to larger ones, meaning that they may coerce to larger integer types providing that the larger integer type has at least the same range as the smaller integer type. We have done this so that the operation `div_3 * 2 + div_5` provides us a `u2` value, or enough to fit two booleans.

```zig
pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var count: u8 = 1;

    while (count <= 100) : (count += 1) {
        const div_3: u2 = @intFromBool(count % 3 == 0);
        const div_5 = @intFromBool(count % 5 == 0);

        switch (div_3 * 2 + div_5) {
            0b10 => try stdout.writeAll("Fizz\n"),
            0b11 => try stdout.writeAll("Fizz Buzz\n"),
            0b01 => try stdout.writeAll("Buzz\n"),
            0b00 => try stdout.print("{}\n", .{count}),
        }
    }
}
```

We can rewrite the switch value to use bitwise operations. This is equivalent to the operation performed above.

```zig
switch (div_3 << 1 | div_5) {
```

### Wrapping Up

Here you've successfully written two *Fizz Buzz* programs using some of Zig's basic arithmetic and control flow primitives. Hopefully you feel introduced to the basics of writing Zig code. Don't worry if you didn't understand it all.
