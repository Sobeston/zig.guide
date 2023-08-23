---
title: "Chapter 1 - Basics"
weight: 2
date: 2023-04-28 18:00:00
description: "Chapter 1 - This will get you up to speed with almost all of the Zig programming language. This part of the tutorial should be coverable in under an hour."
---

## Assignment

Value assignment has the following syntax: `(const|var) identifier[: type] = value`.

* `const` indicates that `identifier` is a **constant** that stores an immutable value.
* `var` indicates that `identifier` is a **variable** that stores a mutable value.
* `: type` is a type annotation for `identifier`, and may be omitted if the data type of `value` can be inferred.

<!--no_test-->
```zig
const constant: i32 = 5;  // signed 32-bit constant
var variable: u32 = 5000; // unsigned 32-bit variable

// @as performs an explicit type coercion
const inferred_constant = @as(i32, 5);
var inferred_variable = @as(u32, 5000);
```

Constants and variables *must* have a value. If no known value can be given, the [`undefined`](https://ziglang.org/documentation/master/#undefined) value, which coerces to any type, may be used as long as a type annotation is provided.

<!--no_test-->
```zig
const a: i32 = undefined;
var b: u32 = undefined;
```

Where possible, `const` values are preferred over `var` values.

## Arrays [N]T

Arrays are denoted by `[N]T`, where `N` is the number of elements in the array and `T` is the type of those elements (i.e., the array's child type).

For array literals, `N` may be replaced by `_` to infer the size of the array.

<!--no_test-->
```zig
const a = [5]u8{ 'h', 'e', 'l', 'l', 'o' };
const b = [_]u8{ 'w', 'o', 'r', 'l', 'd' };
```

To get the size of an array, simply access the array's `len` field.

<!--no_test-->
```zig
const array = [_]u8{ 'h', 'e', 'l', 'l', 'o' };
const length = array.len; // 5
```

## If

Zig's basic if statement is simple in that it only accepts a `bool` value (of values `true` or `false`). There is no concept of truthy or falsy values.

Here we will introduce testing. Save the below code and compile + run it with `zig test file-name.zig`. We will be using the [`expect`](https://ziglang.org/documentation/master/std/#std;testing.expect) function from the standard library, which will cause the test to fail if it's given the value `false`. When a test fails, the error and stack trace will be shown.

```zig
const expect = @import("std").testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    try expect(x == 1);
}
```

If statements also work as expressions.

```zig
test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    try expect(x == 1);
}
```

## While

Zig's while loop has three parts - a condition, a block and a continue expression.

Without a continue expression.
```zig
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    try expect(i == 128);
}
```

With a continue expression.
```zig
test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    try expect(sum == 55);
}
```

With a `continue`.

```zig
test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    try expect(sum == 4);
}
```

With a `break`.

```zig
test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    try expect(sum == 1);
}
```

## For
For loops are used to iterate over arrays (and other types, to be discussed later). For loops follow this syntax. Like while, for loops can use `break` and `continue`. Here we've had to assign values to `_`, as Zig does not allow us to have unused values.

```zig
test "for" {
    //character literals are equivalent to integer literals
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string, 0..) |character, index| {
        _ = character;
        _ = index;
    }

    for (string) |character| {
        _ = character;
    }

    for (string, 0..) |_, index| {
        _ = index;
    }

    for (string) |_| {}
}
```

## Functions

__All function arguments are immutable__ - if a copy is desired the user must explicitly make one. Unlike variables which are snake_case, functions are camelCase. Here's an example of declaring and calling a simple function.

```zig
fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    try expect(@TypeOf(y) == u32);
    try expect(y == 5);
}
```

Recursion is allowed:

```zig
fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    try expect(x == 55);
}
```
When recursion happens, the compiler is no longer able to work out the maximum stack size. This may result in unsafe behaviour - a stack overflow. Details on how to achieve safe recursion will be covered in future.

Values can be ignored by using `_` in place of a variable or const declaration. This does not work at the global scope (i.e. it only works inside functions and blocks), and is useful for ignoring the values returned from functions if you do not need them.

<!--no_test-->
```zig
_ = 10;
```

## Defer

Defer is used to execute a statement while exiting the current block.

```zig
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        try expect(x == 5);
    }
    try expect(x == 7);
}
```

When there are multiple defers in a single block, they are executed in reverse order.

```zig
test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    try expect(x == 4.5);
}
```

## Errors

An error set is like an enum (details on Zig's enums later), where each error in the set is a value. There are no exceptions in Zig; errors are values. Let's create an error set.

```zig
const FileOpenError = error{
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};
```
Error sets coerce to their supersets.

```zig
const AllocationError = error{OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    try expect(err == FileOpenError.OutOfMemory);
}
```

An error set type and a normal type can be combined with the `!` operator to form an error union type. Values of these types may be an error value, or a value of the normal type.

Let's create a value of an error union type. Here [`catch`](https://ziglang.org/documentation/master/#catch) is used, which is followed by an expression which is evaluated when the value before it is an error. The catch here is used to provide a fallback value, but could instead be a [`noreturn`](https://ziglang.org/documentation/master/#noreturn) - the type of `return`, `while (true)` and others.

```zig
test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    try expect(@TypeOf(no_error) == u16);
    try expect(no_error == 10);
}
```

Functions often return error unions. Here's one using a catch, where the `|err|` syntax receives the value of the error. This is called __payload capturing__, and is used similarly in many places. We'll talk about it in more detail later in the chapter. Side note: some languages use similar syntax for lambdas - this is not the case for Zig.

```zig
fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        try expect(err == error.Oops);
        return;
    };
}
```

`try x` is a shortcut for `x catch |err| return err`, and is commonly used in places where handling an error isn't appropriate. Zig's [`try`](https://ziglang.org/documentation/master/#try) and [`catch`](https://ziglang.org/documentation/master/#catch) are unrelated to try-catch in other languages.

```zig
fn failFn() error{Oops}!i32 {
    try failingFunction();
    return 12;
}

test "try" {
    var v = failFn() catch |err| {
        try expect(err == error.Oops);
        return;
    };
    try expect(v == 12); // is never reached
}
```

[`errdefer`](https://ziglang.org/documentation/master/#errdefer) works like [`defer`](https://ziglang.org/documentation/master/#defer), but only executing when the function is returned from with an error inside of the [`errdefer`](https://ziglang.org/documentation/master/#errdefer)'s block.

```zig
var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        try expect(err == error.Oops);
        try expect(problems == 99);
        return;
    };
}
```

Error unions returned from a function can have their error sets inferred by not having an explicit error set. This inferred error set contains all possible errors which the function may return.

```zig
fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();

    //Zig does not let us ignore error unions via _ = x;
    //we must unwrap it with "try", "catch", or "if" by any means
    _ = x catch {};
}
```

Error sets can be merged.

```zig
const A = error{ NotDir, PathNotFound };
const B = error{ OutOfMemory, PathNotFound };
const C = A || B;
```

`anyerror` is the global error set which due to being the superset of all error sets, can have an error from any set coerce to a value of it. Its usage should be generally avoided.

## Switch

Zig's `switch` works as both a statement and an expression. The types of all branches must coerce to the type which is being switched upon. All possible values must have an associated branch - values cannot be left out. Cases cannot fall through to other branches.

An example of a switch statement. The else is required to satisfy the exhaustiveness of this switch.

```zig
test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    try expect(x == 1);
}
```

Here is the former, but as a switch expression.
```zig
test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    try expect(x == 1);
}
```

## Runtime Safety

Zig provides a level of safety, where problems may be found during execution. Safety can be left on, or turned off. Zig has many cases of so-called __detectable illegal behaviour__, meaning that illegal behaviour will be caught (causing a panic) with safety on, but will result in undefined behaviour with safety off. Users are strongly recommended to develop and test their software with safety on, despite its speed penalties.

For example, runtime safety protects you from out of bounds indices.

<!--fail_test-->
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

The user may choose to disable runtime safety for the current block by using the built-in function [`@setRuntimeSafety`](https://ziglang.org/documentation/master/#setRuntimeSafety).

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

## Unreachable

[`unreachable`](https://ziglang.org/documentation/master/#unreachable) is an assertion to the compiler that this statement will not be reached. It can be used to tell the compiler that a branch is impossible, which the optimiser can then take advantage of. Reaching an [`unreachable`](https://ziglang.org/documentation/master/#unreachable) is detectable illegal behaviour.

As it is of the type [`noreturn`](https://ziglang.org/documentation/master/#noreturn), it is compatible with all other types. Here it coerces to u32.
<!--fail_test-->
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
```zig
fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    try expect(asciiToUpper('a') == 'A');
    try expect(asciiToUpper('A') == 'A');
}
```

## Pointers `*T`

Normal pointers in Zig aren't allowed to have 0 or null as a value. They follow the syntax `*T`, where `T` is the child type.

Referencing is done with `&variable`, and dereferencing is done with `variable.*`.

```zig
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    try expect(x == 2);
}
```

Trying to set a `*T` to the value 0 is detectable illegal behaviour.

<!--fail_test-->
```zig
test "naughty pointer" {
    var x: u16 = 0;
    var y: *u8 = @intToPtr(*u8, x);
    _ = y;
}
```
```
test "naughty pointer"...cast causes pointer to be null
.\tests.zig:3:18: error: invalid builtin function: '@intToPtr'
    var y: *u8 = @intToPtr(*u8, x);
                 ^~~~~~~~~~~~~~~~~
```

Zig also has const pointers, which cannot be used to modify the referenced data. Referencing a const variable will yield a const pointer.

<!--fail_test-->
```zig
test "const pointers" {
    const x: u8 = 1;
    var y = &x;
    y.* += 1;
}
```
```
error: cannot assign to constant
    y.* += 1;
        ^
```

A `*T` coerces to a `*const T`.


## Pointer sized integers: `usize` and `isize`

`usize` and `isize` are given as unsigned and signed integers which are the same size as pointers.

```zig
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}
```

## Many-Item Pointers `[*]T`

Sometimes you may have a pointer to an unknown amount of elements. `[*]T` is the solution for this, which works like `*T` but also supports indexing syntax, pointer arithmetic, and slicing. Unlike `*T`, it cannot point to a type which does not have a known size. `*T` coerces to `[*]T`.

These many pointers may point to any amount of elements, including 0 and 1.

## Slices `[]T`

Slices can be thought of as a pair of `[*]T` (the pointer to the data) and a `usize` (the element count). Their syntax is given as `[]T`, with `T` being the child type. Slices are used heavily throughout Zig for when you need to operate on arbitrary amounts of data. Slices have the same attributes as pointers, meaning that there also exists const slices. For loops also operate over slices. String literals in Zig coerce to `[]const u8`.

Here, the syntax `x[n..m]` is used to create a slice from an array. This is called __slicing__, and creates a slice of the elements starting at `x[n]` and ending at `x[m - 1]`. This example uses a const slice as the values which the slice points to do not need to be modified.

```zig
fn total(values: []const u8) usize {
    var sum: usize = 0;
    for (values) |v| sum += v;
    return sum;
}
test "slices" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(total(slice) == 6);
}
```

When these `n` and `m` values are both known at compile time, slicing will actually produce a pointer to an array. This is not an issue as a pointer to an array i.e. `*[N]T` will coerce to a `[]T`.

```zig
test "slices 2" {
    const array = [_]u8{ 1, 2, 3, 4, 5 };
    const slice = array[0..3];
    try expect(@TypeOf(slice) == *const [3]u8);
}
```

The syntax `x[n..]` can also be used for when you want to slice to the end.

```zig
test "slices 3" {
    var array = [_]u8{ 1, 2, 3, 4, 5 };
    var slice = array[0..];
    _ = slice;
}
```

Types that may be sliced are: arrays, many pointers and slices.

## Enums

Zig's enums allow you to define types which have a restricted set of named values.

Let's declare an enum.
```zig
const Direction = enum { north, south, east, west };
```

Enums types may have specified (integer) tag types.
```zig
const Value = enum(u2) { zero, one, two };
```

Enum's ordinal values start at 0. They can be accessed with the built-in function [`@enumToInt`](https://ziglang.org/documentation/master/#enumToInt).
```zig
test "enum ordinal value" {
    try expect(@intFromEnum(Value.zero) == 0);
    try expect(@intFromEnum(Value.one) == 1);
    try expect(@intFromEnum(Value.two) == 2);
}
```

Values can be overridden, with the next values continuing from there.
```zig
const Value2 = enum(u32) {
    hundred = 100,
    thousand = 1000,
    million = 1000000,
    next,
};

test "set enum ordinal value" {
    try expect(@intFromEnum(Value2.hundred) == 100);
    try expect(@intFromEnum(Value2.thousand) == 1000);
    try expect(@intFromEnum(Value2.million) == 1000000);
    try expect(@intFromEnum(Value2.next) == 1000001);
}
```

Methods can be given to enums. These act as namespaced functions that can be called with dot syntax.

```zig
const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
    try expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}
```

Enums can also be given `var` and `const` declarations. These act as namespaced globals, and their values are unrelated and unattached to instances of the enum type.

```zig
const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    try expect(Mode.count == 1);
}
```


## Structs

Structs are Zig's most common kind of composite data type, allowing you to define types that can store a fixed set of named fields. Zig gives no guarantees about the in-memory order of fields in a struct, or its size. Like arrays, structs are also neatly constructed with `T{}` syntax. Here is an example of declaring and filling a struct.
```zig
const Vec3 = struct { x: f32, y: f32, z: f32 };

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
    _ = my_vector;
}
```

All fields must be given a value.

<!--fail_test-->
```zig
test "missing struct field" {
    const my_vector = Vec3{
        .x = 0,
        .z = 50,
    };
    _ = my_vector;
}
```
```
error: missing field: 'y'
    const my_vector = Vec3{
                        ^
```

Fields may be given defaults:
```zig
const Vec4 = struct { x: f32, y: f32, z: f32 = 0, w: f32 = undefined };

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
    _ = my_vector;
}
```

Like enums, structs may also contain functions and declarations.

Structs have the unique property that when given a pointer to a struct, one level of dereferencing is done automatically when accessing fields. Notice how in this example, self.x and self.y are accessed in the swap function without needing to dereference the self pointer.

```zig
const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    try expect(thing.x == 20);
    try expect(thing.y == 10);
}
```

## Unions

Zig's unions allow you to define types which store one value of many possible typed fields; only one field may be active at one time.

Bare union types do not have a guaranteed memory layout. Because of this, bare unions cannot be used to reinterpret memory. Accessing a field in a union which is not active is detectable illegal behaviour.

<!--fail_test-->
```zig
const Result = union {
    int: i64,
    float: f64,
    bool: bool,
};

test "simple union" {
    var result = Result{ .int = 1234 };
    result.float = 12.34;
}
```
```
Test [1/1] test.simple union... thread 6604310 panic: access of union field 'float' while field 'int' is active
./tests.zig:9:11: 0x10487c807 in test.simple union (test)
    result.float = 12.34;
```

Tagged unions are unions which use an enum to detect which field is active. Here we make use of payload capturing again, to switch on the tag type of a union while also capturing the value it contains. Here we use a *pointer capture*; captured values are immutable, but with the `|*value|` syntax we can capture a pointer to the values instead of the values themselves. This allows us to use dereferencing to mutate the original value.

```zig
const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    try expect(value.b == 3);
}
```

The tag type of a tagged union can also be inferred. This is equivalent to the Tagged type above.

<!--no_test-->
```zig
const Tagged = union(enum) { a: u8, b: f32, c: bool };
```

`void` member types can have their type omitted from the syntax. Here, none is of type `void`.

```zig
const Tagged2 = union(enum) { a: u8, b: f32, c: bool, none };
```

## Integer Rules

Zig supports hex, octal and binary integer literals.
```zig
const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xFF;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b11110000;
```
Underscores may also be placed between digits as a visual separator.
```zig
const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0xFF80_0000_0000_0000;
```

"Integer Widening" is allowed, which means that integers of a type may coerce to an integer of another type, providing that the new type can fit all of the values that the old type can.

```zig
test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    try expect(c == a);
}
```

If you have a value stored in an integer that cannot coerce to the type that you want, [`@intCast`](https://ziglang.org/documentation/master/#intCast) may be used to explicitly convert from one type to the other. If the value given is out of the range of the destination type, this is detectable illegal behaviour.

```zig
test "@intCast" {
    const x: u64 = 200;
    const y = @as(u8, @intCast(x));
    try expect(@TypeOf(y) == u8);
}
```

Integers by default are not allowed to overflow. Overflows are detectable illegal behaviour. Sometimes being able to overflow integers in a well defined manner is wanted behaviour. For this use case, Zig provides overflow operators.

| Normal Operator | Wrapping Operator |
|-----------------|-------------------|
| +               | +%                |
| -               | -%                |
| *               | *%                |
| +=              | +%=               |
| -=              | -%=               |
| *=              | *%=               |

```zig
test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    try expect(a == 0);
}
```

## Floats

Zig's floats are strictly IEEE compliant unless [`@setFloatMode(.Optimized)`](https://ziglang.org/documentation/master/#setFloatMode) is used, which is equivalent to GCC's `-ffast-math`. Floats coerce to larger float types.

```zig
test "float widening" {
    const a: f16 = 0;
    const b: f32 = a;
    const c: f128 = b;
    try expect(c == @as(f128, a));
}
```

Floats support multiple kinds of literal.
```zig
const floating_point: f64 = 123.0E+77;
const another_float: f64 = 123.0;
const yet_another: f64 = 123.0e+77;

const hex_floating_point: f64 = 0x103.70p-5;
const another_hex_float: f64 = 0x103.70;
const yet_another_hex_float: f64 = 0x103.70P-5;
```
Underscores may also be placed between digits.
```zig
const lightspeed: f64 = 299_792_458.000_000;
const nanosecond: f64 = 0.000_000_001;
const more_hex: f64 = 0x1234_5678.9ABC_CDEFp-10;
```

Integers and floats may be converted using the built-in functions [`@intToFloat`](https://ziglang.org/documentation/master/#intToFloat) and [`@floatToInt`](https://ziglang.org/documentation/master/#floatToInt). [`@intToFloat`](https://ziglang.org/documentation/master/#intToFloat) is always safe, whereas [`@floatToInt`](https://ziglang.org/documentation/master/#floatToInt) is detectable illegal behaviour if the float value cannot fit in the integer destination type.

```zig
test "int-float conversion" {
    const a: i32 = 0;
    const b = @as(f32, @floatFromInt(a));
    const c = @as(i32, @intFromFloat(b));
    try expect(c == a);
}
```

## Labelled Blocks `:blk {}`

Blocks in Zig are expressions and can be given labels, which are used to yield values. Here, we are using a label called blk. Blocks yield values, meaning that they can be used in place of a value. The value of an empty block `{}` is a value of the type `void`.

```zig
test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    try expect(count == 45);
    try expect(@TypeOf(count) == u32);
}
```

This can be seen as being equivalent to C's `i++`.
<!--no_test-->
```zig
blk: {
    const tmp = i;
    i += 1;
    break :blk tmp;
}
```

## Labelled Loops

Loops can be given labels, allowing you to `break` and `continue` to outer loops.

```zig
test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    try expect(count == 8);
}
```

## Loops as expressions

Like `return`, `break` accepts a value. This can be used to yield a value from a loop. Loops in Zig also have an `else` branch on loops, which is evaluated when the loop is not exited from with a `break`.

```zig
fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    try expect(rangeHasNumber(0, 10, 3));
}
```

## Optionals `?T`

Optionals use the syntax `?T` and are used to store the data [`null`](https://ziglang.org/documentation/master/#null), or a value of type `T`.

```zig
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{ 1, 2, 3, 4, 5, 6, 7, 8, 12 };
    for (data, 0..) |v, i| {
        if (v == 10) found_index = i;
    }
    try expect(found_index == null);
}
```

Optionals support the `orelse` expression, which acts when the optional is [`null`](https://ziglang.org/documentation/master/#null). This unwraps the optional to its child type.

```zig
test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    try expect(b == 0);
    try expect(@TypeOf(b) == f32);
}
```

`.?` is a shorthand for `orelse unreachable`. This is used for when you know it is impossible for an optional value to be null, and using this to unwrap a [`null`](https://ziglang.org/documentation/master/#null) value is detectable illegal behaviour.

```zig
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    try expect(b == c);
    try expect(@TypeOf(c) == f32);
}
```

Payload capturing works in many places for optionals, meaning that in the event that it is non-null we can "capture" its non-null value.

Here we use an `if` optional payload capture; a and b are equivalent here. `if (b) |value|` captures the value of `b` (in the cases where `b` is not null), and makes it available as `value`. As in the union example, the captured value is immutable, but we can still use a pointer capture to modify the value stored in `b`.

```zig
test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
        _ = value;
    }

    var b: ?i32 = 5;
    if (b) |*value| {
        value.* += 1;
    }
    try expect(b.? == 6);
}
```

And with `while`:
```zig
var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    try expect(sum == 6); // 3 + 2 + 1
}
```

Optional pointer and optional slice types do not take up any extra memory, compared to non-optional ones. This is because internally they use the 0 value of the pointer for `null`.

This is how null pointers in Zig work - they must be unwrapped to a non-optional before dereferencing, which stops null pointer dereferences from happening accidentally.

## Comptime

Blocks of code may be forcibly executed at compile time using the [`comptime`](https://ziglang.org/documentation/master/#comptime) keyword. In this example, the variables x and y are equivalent.

```zig
test "comptime blocks" {
    var x = comptime fibonacci(10);
    _ = x;

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
    _ = y;
}
```

Integer literals are of the type `comptime_int`. These are special in that they have no size (they cannot be used at runtime!), and they have arbitrary precision. `comptime_int` values coerce to any integer type that can hold them. They also coerce to floats. Character literals are of this type.

```zig
test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    _ = c;
    const d: f32 = b;
    _ = d;
}
```

`comptime_float` is also available, which internally is an `f128`. These cannot be coerced to integers, even if they hold an integer value.

Types in Zig are values of the type `type`. These are available at compile time. We have previously encountered them by checking [`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf) and comparing with other types, but we can do more.

```zig
test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
    _ = b;
}
```

Function parameters in Zig can be tagged as being [`comptime`](https://ziglang.org/documentation/master/#comptime). This means that the value passed to that function parameter must be known at compile time. Let's make a function that returns a type. Notice how this function is PascalCase, as it returns a type.

```zig
fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    try expect(Matrix(f32, 4, 4) == [4][4]f32);
}
```

We can reflect upon types using the built-in [`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo), which takes in a `type` and returns a tagged union. This tagged union type can be found in [`std.builtin.TypeInfo`](https://ziglang.org/documentation/master/std/#std;builtin.TypeInfo) (info on how to make use of imports and std later).

```zig
fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    try expect(@TypeOf(x) == u16);
    try expect(x == 50);
}
```

We can use the [`@Type`](https://ziglang.org/documentation/master/#Type) function to create a type from a [`@typeInfo`](https://ziglang.org/documentation/master/#typeInfo). [`@Type`](https://ziglang.org/documentation/master/#Type) is implemented for most types but is notably unimplemented for enums, unions, functions, and structs.

Here anonymous struct syntax is used with `.{}`, because the `T` in `T{}` can be inferred. Anonymous structs will be covered in detail later. In this example we will get a compile error if the `Int` tag isn't set.

```zig
fn GetBiggerInt(comptime T: type) type {
    return @Type(.{
        .Int = .{
            .bits = @typeInfo(T).Int.bits + 1,
            .signedness = @typeInfo(T).Int.signedness,
        },
    });
}

test "@Type" {
    try expect(GetBiggerInt(u8) == u9);
    try expect(GetBiggerInt(i31) == i32);
}
```

Returning a struct type is how you make generic data structures in Zig. The usage of [`@This`](https://ziglang.org/documentation/master/#This) is required here, which gets the type of the innermost struct, union, or enum. Here [`std.mem.eql`](https://ziglang.org/documentation/master/std/#std;mem.eql) is also used which compares two slices.

```zig
fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data, 0..) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    try expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}
```

The types of function parameters can also be inferred by using `anytype` in place of a type. [`@TypeOf`](https://ziglang.org/documentation/master/#TypeOf) can then be used on the parameter.

```zig
fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    try expect(plusOne(@as(u32, 1)) == 2);
}
```

Comptime also introduces the operators `++` and `**` for concatenating and repeating arrays and slices. These operators do not work at runtime.

```zig
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    try expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    try expect(eql(u8, &memory, &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }));
}
```

## Payload Captures `|n|`

Payload captures use the syntax `|value|` and appear in many places, some of which we've seen already. Wherever they appear, they are used to "capture" the value from something.

With if statements and optionals.
```zig
test "optional-if" {
    var maybe_num: ?usize = 10;
    if (maybe_num) |n| {
        try expect(@TypeOf(n) == usize);
        try expect(n == 10);
    } else {
        unreachable;
    }
}
```

With if statements and error unions. The else with the error capture is required here.
```zig
test "error union if" {
    var ent_num: error{UnknownEntity}!u32 = 5;
    if (ent_num) |entity| {
        try expect(@TypeOf(entity) == u32);
        try expect(entity == 5);
    } else |err| {
        _ = err catch {};
        unreachable;
    }
}
```

With while loops and optionals. This may have an else block.
```zig
test "while optional" {
    var i: ?u32 = 10;
    while (i) |num| : (i.? -= 1) {
        try expect(@TypeOf(num) == u32);
        if (num == 1) {
            i = null;
            break;
        }
    }
    try expect(i == null);
}
```

With while loops and error unions. The else with the error capture is required here.

```zig
var numbers_left2: u32 = undefined;

fn eventuallyErrorSequence() !u32 {
    return if (numbers_left2 == 0) error.ReachedZero else blk: {
        numbers_left2 -= 1;
        break :blk numbers_left2;
    };
}

test "while error union capture" {
    var sum: u32 = 0;
    numbers_left2 = 3;
    while (eventuallyErrorSequence()) |value| {
        sum += value;
    } else |err| {
        try expect(err == error.ReachedZero);
    }
}
```

For loops.
```zig
test "for capture" {
    const x = [_]i8{ 1, 5, 120, -5 };
    for (x) |v| try expect(@TypeOf(v) == i8);
}
```

Switch cases on tagged unions.
```zig
const Info = union(enum) {
    a: u32,
    b: []const u8,
    c,
    d: u32,
};

test "switch capture" {
    var b = Info{ .a = 10 };
    const x = switch (b) {
        .b => |str| blk: {
            try expect(@TypeOf(str) == []const u8);
            break :blk 1;
        },
        .c => 2,
        //if these are of the same type, they
        //may be inside the same capture group
        .a, .d => |num| blk: {
            try expect(@TypeOf(num) == u32);
            break :blk num * 2;
        },
    };
    try expect(x == 20);
}
```

As we saw in the Union and Optional sections above, values captured with the `|val|` syntax are immutable (similar to function arguments), but we can use pointer capture to modify the original values. This captures the values as pointers that are themselves still immutable, but because the value is now a pointer, we can modify the original value by dereferencing it:

```zig
test "for with pointer capture" {
    var data = [_]u8{ 1, 2, 3 };
    for (&data) |*byte| byte.* += 1;
    try expect(eql(u8, &data, &[_]u8{ 2, 3, 4 }));
}
```

## Inline Loops

`inline` loops are unrolled, and allow some things to happen which only work at compile time. Here we use a [`for`](https://ziglang.org/documentation/master/#inline-for), but a [`while`](https://ziglang.org/documentation/master/#inline-while) works similarly.
```zig
test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    try expect(sum == 10);
}
```

Using these for performance reasons is inadvisable unless you've tested that explicitly unrolling is faster; the compiler tends to make better decisions here than you.

## Opaque

[`opaque`](https://ziglang.org/documentation/master/#opaque) types in Zig have an unknown (albeit non-zero) size and alignment. Because of this these data types cannot be stored directly. These are used to maintain type safety with pointers to types that we don't have information about.

<!--fail_test-->
```zig
const Window = opaque {};
const Button = opaque {};

extern fn show_window(*Window) callconv(.C) void;

test "opaque" {
    var main_window: *Window = undefined;
    show_window(main_window);

    var ok_button: *Button = undefined;
    show_window(ok_button);
}
```
```
./test-c1.zig:653:17: error: expected type '*Window', found '*Button'
    show_window(ok_button);
                ^
./test-c1.zig:653:17: note: pointer type child 'Button' cannot cast into pointer type child 'Window'
    show_window(ok_button);
                ^
```

Opaque types may have declarations in their definitions (the same as structs, enums and unions).

<!--no_test-->
```zig
const Window = opaque {
    fn show(self: *Window) void {
        show_window(self);
    }
};

extern fn show_window(*Window) callconv(.C) void;

test "opaque with declarations" {
    var main_window: *Window = undefined;
    main_window.show();
}
```

The typical usecase of opaque is to maintain type safety when interoperating with C code that does not expose complete type information.

## Anonymous Structs `.{}`

The struct type may be omitted from a struct literal. These literals may coerce to other struct types.

```zig
test "anonymous struct literal" {
    const Point = struct { x: i32, y: i32 };

    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    try expect(pt.x == 13);
    try expect(pt.y == 67);
}
```

Anonymous structs may be completely anonymous i.e. without being coerced to another struct type.

```zig
test "fully anonymous struct" {
    try dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) !void {
    try expect(args.int == 1234);
    try expect(args.float == 12.34);
    try expect(args.b);
    try expect(args.s[0] == 'h');
    try expect(args.s[1] == 'i');
}
```
<!-- TODO: mention tuple slicing when it's implemented -->

Anonymous structs without field names may be created, and are referred to as __tuples__. These have many of the properties that arrays do; tuples can be iterated over, indexed, can be used with the `++` and `**` operators, and have a len field. Internally, these have numbered field names starting at `"0"`, which may be accessed with the special syntax `@"0"` which acts as an escape for the syntax - things inside `@""` are always recognised as identifiers.

An `inline` loop must be used to iterate over the tuple here, as the type of each tuple field may differ.

```zig
test "tuple" {
    const values = .{
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi",
    } ++ .{false} ** 2;
    try expect(values[0] == 1234);
    try expect(values[4] == false);
    inline for (values, 0..) |v, i| {
        if (i != 2) continue;
        try expect(v);
    }
    try expect(values.len == 6);
    try expect(values.@"3"[0] == 'h');
}
```

## Sentinel Termination: `[N:t]T`, `[:t]T`, and `[*:t]T`

Arrays, slices and many pointers may be terminated by a value of their child type. This is known as sentinel termination. These follow the syntax `[N:t]T`, `[:t]T`, and `[*:t]T`, where `t` is a value of the child type `T`.

An example of a sentinel terminated array. The built-in [`@bitCast`](https://ziglang.org/documentation/master/#bitCast) is used to perform an unsafe bitwise type conversion. This shows us that the last element of the array is followed by a 0 byte.

```zig
test "sentinel termination" {
    const terminated = [3:0]u8{ 3, 2, 1 };
    try expect(terminated.len == 3);
    try expect(@as(*const [4]u8, @ptrCast(&terminated))[3] == 0);
}
```

The types of string literals is `*const [N:0]u8`, where N is the length of the string. This allows string literals to coerce to sentinel terminated slices, and sentinel terminated many pointers. Note: string literals are UTF-8 encoded.

```zig
test "string literal" {
    try expect(@TypeOf("hello") == *const [5:0]u8);
}
```

`[*:0]u8` and `[*:0]const u8` perfectly model C's strings.

```zig
test "C string" {
    const c_string: [*:0]const u8 = "hello";
    var array: [5]u8 = undefined;

    var i: usize = 0;
    while (c_string[i] != 0) : (i += 1) {
        array[i] = c_string[i];
    }
}
```

Sentinel terminated types coerce to their non-sentinel-terminated counterparts.

```zig
test "coercion" {
    var a: [*:0]u8 = undefined;
    const b: [*]u8 = a;
    _ = b;

    var c: [5:0]u8 = undefined;
    const d: [5]u8 = c;
    _ = d;

    var e: [:10]f32 = undefined;
    const f = e;
    _ = f;
}
```

Sentinel terminated slicing is provided which can be used to create a sentinel terminated slice with the syntax `x[n..m:t]`, where `t` is the terminator value. Doing this is an assertion from the programmer that the memory is terminated where it should be - getting this wrong is detectable illegal behaviour.

```zig
test "sentinel terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3 :0];
    _ = y;
}
```

## Vectors

Zig provides vector types for SIMD. These are not to be conflated with vectors in a mathematical sense, or vectors like C++'s std::vector (for this, see "Arraylist" in chapter 2). Vectors may be created using the [`@Type`](https://ziglang.org/documentation/master/#Type) built-in we used earlier, and [`std.meta.Vector`](https://ziglang.org/documentation/master/std/#std;meta.Vector) provides a shorthand for this.

Vectors can only have child types of booleans, integers, floats and pointers.

Operations between vectors with the same child type and length can take place. These operations are performed on each of the values in the vector.[`std.meta.eql`](https://ziglang.org/documentation/master/std/#std;meta.eql) is used here to check for equality between two vectors (also useful for other types like structs).

```zig
const meta = @import("std").meta;

test "vector add" {
    const x: @Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: @Vector(4, f32) = .{ 2, 10, 0, 1 };
    const z = x + y;
    try expect(meta.eql(z, @Vector(4, f32){ 3, 0, 20, 0 }));
}
```

Vectors are indexable.
```zig
test "vector indexing" {
    const x: @Vector(4, u8) = .{ 255, 0, 255, 0 };
    try expect(x[0] == 255);
}
```

The built-in function [`@splat`](https://ziglang.org/documentation/master/#splat) may be used to construct a vector where all of the values are the same. Here we use it to multiply a vector by a scalar.

```zig
test "vector * scalar" {
    const x: @Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const vec: @Vector(3, f32) = @splat(2);
    const y = x * vec;
    try expect(meta.eql(y, @Vector(3, f32){ 25, 75, 5 }));
}
```

Vectors do not have a `len` field like arrays, but may still be looped over. Here, [`std.mem.len`](https://ziglang.org/documentation/master/std/#std;mem.len) is used as a shortcut for `@typeInfo(@TypeOf(x)).Vector.len`.

```zig
const len = @import("std").mem.len;

test "vector looping" {
    const x = @Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk: {
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < 4) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    try expect(sum == 510);
}
```

Vectors coerce to their respective arrays.

```zig
const arr: [4]f32 = @Vector(4, f32){ 1, 2, 3, 4 };
```

It is worth noting that using explicit vectors may result in slower software if you do not make the right decisions - the compiler's auto-vectorisation is fairly smart as-is.

## Imports

The built-in function [`@import`](https://ziglang.org/documentation/master/#import) takes in a file, and gives you a struct type based on that file. All declarations labelled as `pub` (for public) will end up in this struct type, ready for use.

`@import("std")` is a special case in the compiler, and gives you access to the standard library. Other [`@import`](https://ziglang.org/documentation/master/#import)s will take in a file path, or a package name (more on packages in a later chapter).

We will explore more of the standard library in later chapters.

## End Of Chapter 1
In the next chapter we will cover standard patterns, including many useful areas of the standard library.

Feedback and PRs are welcome.
