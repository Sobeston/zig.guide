---
title: "Chapter 1 - Basics"
weight: 2
---

# Bit Sized integers
Zig provides bit-sized integers in the format `iN` (signed), and `uN` (unsigned). Here, `N` can be anywhere in the range 0-65535 (inclusive). Examples: `u8`, `u1`, `i32`, `u64`, `i40`.

# Assignment

Variables and constants can be assigned like so:
```zig
var some_variable: i32 = 5;
const some_constant: u64 = 5000;
```

Here `var` declares a variable of the name `some_variable`, the type `i32`, and the value `5`. The key difference between `var` and `const` is that `var` creates a variable, which allows you to change its value after declaration whilst `const` disallows you from modifying its value.

`const` is preferable over `var` where possible.

A variable cannot be declared without a value, the user must explicitly use `undefined` as its value.

# Integer literals

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



# Integer Widening

"Integer Widening" is allowed, which means that integers of a type may coerce to an integer of another type, providing that the new type can fit all of the values that the old type can.

```zig
const expect = @import("std").testing.expect;

test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    // expect takes in a bool, and will panic if that bool is false.
    // expect is only to be used within tests.
    expect(c == a);
}
```
###### (These tests can be run by using `zig test file-name.zig`. If we do not display an error, that means that the test passes successfully)

# Runtime Safety

Zig provides a level of safety, where problems may be found during execution. Safety can be left on, or turned off. Zig has many cases of so-called __detectable illegal behaviour__, meaning that illegal behaviour will be caught (causing a panic) with safety on, but will result in undefined behaviour with safety off. Users are strongly recommended to develop and test their software with safety on, despite its speed penalties.

An example of this is integer overflows - Zig's safety features will stop normal integer operations such as `+` and `-` from causing an integer to overflow.

```zig
test "overflow" {
    var a: u8 = 255;
    a += 1;
}
```
```
test "overflow"...integer overflow
\tests.zig:12:7: 0x7ff64ba31a3f in test "overflow" (test.obj)
    a += 1;
      ^
```

Here, safety caused a panic and stopped execution when it detected the overflow. The user may also choose to disable runtime safety for the current block by using the built-in function `@setRuntimeSafety`. It is worth noting that overflowing here is undefined behaviour - the value of `a` at the end isn't necessarily 0.

```zig
test "overflow safety off" {
    @setRuntimeSafety(false);
    var a: u8 = 255;
    a += 1;
}
```

# Wrapping Operators

Sometimes being able to overflow integers in a well defined manner is wanted behaviour. For this use case, Zig provides overflow operators.

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
    expect(a == 0);
}
```

# Floats

Zig provides the floats `f16`, `f32`, `f64`, `f128`. These are strictly IEEE compliant unless `@setFloatMode(.Optimized)` is used, which is equivalent to GCC's `-ffast-math`. Like integers, floats may be "widened" to larger types.

```zig
test "float widening" {
    const a: f16 = 1;
    const b: f32 = a;
    const c: f64 = b;
    const d: f128 = c;
    expect(d == a);
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

# Arrays

Arrays use the syntax `[N]T`, where `N` (a natural number) is the number of elements, and `T` is the type of the elements, the s the so-called "child type" of the array. Examples: `[100]u8`, `[3]f32`, `[4]u32`, `[2]u40`.

A notable feature about Zig is that all values are constructed as literals, or are constructed using `T{}` syntax. Here's an example of creating an array:
```zig
test "array" {
    const a = [3]u8{ 1, 2, 3 };
}
```
Here, the type is left out of the left hand side of the variable declaration. This is because the type can be inferred from the right hand side.

The syntax `[_]` may be used when constructing an array from a literal, and the compiler will set the array type to the correct length.

Zig's runtime safety protects you from out of bounds indices:

```zig
test "out of bounds" {
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
}
```
```
test "out of bounds"...index out of bounds
\tests.zig:43:14: 0x7ff698cc1b82 in test "out of bounds" (test.obj)
    const b = a[index];
             ^
```

# For

Zig's for loops can work over an array, and will provide you the values and indices. `break` and `continue` are also available to you.

```zig
test "array sum" {
    const a = [3]u8{ 1, 2, 3 };
    var sum: u8 = 0;
    for (a) |value, index| {
        sum += value;
    }
    expect(sum == 6);
}
```

The value or index can be ignored by replacing it with `_`,
```zig
for (a) |value, _| {
    sum += value;
}
```
and in the case of the index can be left out entirely.
```zig
for (a) |value| {
    sum += value;
}
```
A single statement may be used in place of a block.
```zig
for (a) |value| sum += value;
```

# If

Zig provides a normal if statement, which accepts a bool. Notably, unlike other languages, Zig does not have the concept of truthy or falsy values.

```zig
test "if" {
    var x: u32 = 0;
    if (x < 10) {
        x += 10;
    }
    expect(x == 10);
}
```

Zig's if statement also works as an expression.

```zig
test "if expression" {
    var x: u32 = 0;
    x += if (x < 10) @as(u32, 10) else 0;
    expect(x == 10);
}
```

Here, the built-in function `@as` is used to give the value "10" the type `u32`. This will not be necessary in future versions of the compiler.

# While

Zig's while loop has three parts - a condition, a block and a continue expression. Like for loops, `break` and `continue` may be used.

Without a continue expression:
```zig
test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    expect(i == 128);
}
```
With a continue expression:
```zig
test "while with continue expression" {
    var count: u64 = 0;
    var i: u8 = 2;
    while (i < 100) : (i *= 2) {
        count += i;
    }
    expect(count == 126);
}
```

# Functions

__All function arguments are immutable__ - if a copy is desired the user must explicitly make one. Unlike variables which are snake_case, functions are camelCase. Here's an example of declaring and calling a simple function:

```zig
fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    expect(@TypeOf(y) == u32);
    expect(y == 5);
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
    expect(x == 55);
}
```
When recursion happens, the compiler is no longer able to work out the maximum stack size. This may result in unsafe behaviour - a stack overflow. Doing this safely will be covered later.

# Defer

Defer is used to execute a statement while exiting the current block.

```zig
test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        expect(x == 5);
    }
    expect(x == 7);
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
    expect(x == 4.5);
}
```
Errdefer is the same as defer, but only runs if the block exits with an error (see the next section).

```zig
const print = @import("std").debug.print;

test "errdefer" {
    errdefer print("Oh no! Something went wrong!\n", .{});
    // We can capture the in-flight error
    errdefer |e| print("Exiting because of {}\n", .{e});

    const b = try trySquare(66000);
}

fn trySquare(n: u32) !u32 {
    if (n >= 65536) {
        return error.wontFit;
    } else return n*n;
}
```

# Errors

Zig's errors work via error values rather than exceptions. Functions may return errors.

In this example `!u8` denotes that the function may return `u8` or an error, where the set of errors is inferred by what errors may be returned from the function. The error set here only contains "InvalidAlphabetCharacter". A value which may be either an error or a value, is called an __error union__.

The expression `catch` is also used here, which allows the user to provide a value or other behaviour if an error occurs. Here, it is needed so that "index" can be of type `u8`, and not an error union.

```zig
fn alphabetIndex(char: u8) !u8 {
    if (char >= 'a' and char <= 'z') return char - 'a';
    if (char >= 'A' and char <= 'Z') return char - 'A';
    return error.InvalidAlphabetCharacter;
}

test "error" {
    const index: u8 = alphabetIndex('b') catch 0;
    expect(index == 1);
}
```

`catch` may also be used with a payload. Here instead of giving a default value, if an error happens the error is returned.

```zig
test "catch payload" {
    const index: u8 = alphabetIndex('b') catch |err| {
        return err;
    };
    expect(index == 1);
}
```

An error returning from a test results in test failure:
```zig
test "bad catch payload" {
    const index: u8 = alphabetIndex('1') catch |err| {
        return err;
    };
    expect(index == 1);
}
```
```
test "bad try"...error: InvalidAlphabetCharacter
\tests.zig:126:5: 0x7ff6f4492861 in alphabetIndex (test.obj)
    return error.InvalidAlphabetCharacter;
    ^
```

The keyword `try` is a shorthand for `catch |err| return err`, and is a common pattern for error handling.

```zig
test "try" {
    const index: u8 = try alphabetIndex('a');
    expect(index == 0);
}
```

Error sets may be explicitly made, rather than inferred. This gives the caller a guarantee (and valuable documentation!) that only errors in the set may be returned.

```zig
fn alphabetIndex2(char: u8) error{InvalidAlphabetCharacter}!u8 {
    if (char >= 'a' and char <= 'z') return char - 'a';
    if (char >= 'A' and char <= 'z') return char - 'A';
    return error.InvalidAlphabetCharacter;
}

test "error set" {
    const index: u8 = try alphabetIndex('a');
    expect(index == 0);
}
```

# Switch

Switches in Zig are expressions where all branches must be coercible to the same type. Branches cannot fall through.

All cases must be handled - an explicit else is required if the other branches do not cover all possibilities.
```zig
test "switch" {
    const x: u8 = 125;
    const y: f32 = switch (x) {
        // Multiple cases can match one branch
        0, 1 => 5,
        // Ranges are also allowed -- these are inclusive
        // on both bounds
        2...100 => 1000,
        101...150 => 5000,
        else => 0,
    };
    expect(y == 5000);
}
```

Switches are particularly useful for error handling.

```zig
fn errorProne(x: i32) error{Even, Zero, Negative}!i32 {
    if (@mod(x, 2) == 0) return error.Even;
    if (x == 0) return error.Zero;
    if (x < 0) return error.Negative;
    return -x;
}

test "switch on error" {
    const value = errorProne(11) catch |err| switch (err) {
        error.Even, error.Zero => 0,
        error.Negative => return err
    };
}
```

# Unreachable

The `unreachable` is as an assertion to the compiler that it is not reachable. If it is reached, this is detectable illegal behaviour (i.e. with safety enabled it will result in a panic, and without safety it will cause undefined behaviour).

Unreachable is often combined with a switch, in order to tell the compiler that a branch is not possible.

```zig
test "unreachable switch" {
    var x: u8 = 100;
    x = switch (x) {
        0...15 => x + 1,
        16...250 => x + 15,
        else => unreachable,
    };
}
```

# Pointers

Normal pointers in Zig aren't allowed to have 0 or null as a value. They follow the syntax `*T`, where `T` is the child type.

Referencing is done with `&variable`, and dereferencing is done with `variable.*`.

```zig
fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    expect(x == 2);
}
```

Zig also has const pointers, which cannot be used to modify the referenced data. Referencing a const variable will yield a const pointer.

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

# Structs

Zig gives no guarantees about the in-memory order of fields in a struct, or its size. Like arrays, structs are also neatly constructed with `T{}` syntax. Types are written with PascalCase.

Declaring and filling a struct:
```zig
const Vec3 = struct {
    x: f32, y: f32, z: f32
};

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
}
```

All fields must be given a value:
```zig
test "missing struct field" {
    const my_vector = Vec3{
        .x = 0,
        .z = 50,
    };
}
```
```
error: missing field: 'y'
    const my_vector = Vec3{
                        ^
```

Fields may be given defaults:
```zig
const Vec4 = struct {
    x: f32, y: f32, z: f32 = 0, w: f32 = undefined
};

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
}
```

Structs may contain declarations. This allows structs to work like namespaces. Here, `max_num` and `min_num` are not fields of the struct, but rather namespaced global constants. This also works with `var`.

```zig
const UnitVector = struct {
    const max_num: f32 = 1;
    const min_num: f32 = -1;
    x: f32,
    y: f32,
    z: f32
};

test "namespaced constant" {
    expect(UnitVector.max_num == 1);
}
```

As structs may contain declarations, they may also have methods. Methods are not special - they are just namespaced functions that may be called with dot syntax.

```zig
const Vec = struct {
    x: f32,
    y: f32,
    z: f32,
    fn init(x: f32, y: f32, z: f32) Vec {
        return Vec{
            .x = x,
            .y = y,
            .z = z,
        };
    }
    pub fn dot(self: Vec, other: Vec) f32 {
        return self.x * other.x + self.y * other.y + self.z * other.z;
    }
};

test "methods" {
    const v1 = Vec.init(1.0, 0.0, 0.0);
    const v2 = Vec.init(0.0, 1.0, 0.0);
    expect(v1.dot(v2) == 0.0);
    expect(Vec.dot(v1, v2) == 0.0);
}
```

# Pointer sized integers

`usize` and `isize` are given as unsigned and signed integers which are the same size as pointers. 

```zig
test "usize" {
    expect(@sizeOf(usize) == @sizeOf(*u8));
    expect(@sizeOf(isize) == @sizeOf(*u8));
}
```

# Multi Pointers

Sometimes you may have a pointer to an unknown amount of elements. `[*]T` is the solution for this, which works like `*T` but also supports indexing syntax, pointer arithmetic, and slicing. Unlike `*T`, it cannot point to a type which does not have a known size. `*T` coerces to `[*]T`.

# Slices

Slices can be thought of as structs with a field containing a multi pointer, and a field containing the count of elements (which is of type `usize`). Their syntax is given as `[]T`, with `T` being the child type. Slices are used heavily throughout Zig for when you need to operate on arbitrary amounts of data. Slices have the same attributes as pointers, meaning that there also exists const slices. For loops also operate over slices. String literals in zig coerce to `[]const u8`.



Here, the syntax `x[n..m]` is used to create a slice from an array. This is called __slicing__, and creates a slice of the elements starting at `x[n]` and ending at `x[m - 1]`. This example uses a const slice as the values which the slice points to do not need to be modified.

```zig
fn total(values: []const u8) usize {
    var count: usize = 0;
    for (values) |v| count += v;
    return count;
}
test "slices" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array[0..3];
    expect(total(slice) == 6);
}
```

When these `n` and `m` values are both known at compile time, slicing will actually produce a pointer to an array. This is not an issue as a pointer to an array i.e. `*[N]T` will coerce to a `[]T`.

```zig
test "slices 2" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array[0..3];
    expect(@TypeOf(slice) == *[3]u8);
}
```

The syntax `x[n..]` can also be used for when you want to slice to the end.

```zig
test "slices 3" {
    var array = [_]u8{1, 2, 3, 4, 5};
    var slice = array[0..];
}
```

Types that may be sliced are: arrays, multi pointers and slices.

# Optionals

Optionals use the syntax `?T` and are used to store the data `null`, or a value of type `T`.

```zig
test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{1, 2, 3, 4, 5, 6, 7, 8, 12};
    for (data) |v, i| {
        if (v == 10) found_index = i;
    }
    expect(found_index == null);
}
```

Optionals support the `orelse` expression, which acts when the optional is `null`. This unwraps the optional to its child type.

```zig
test "orelse" {
    const a: ?f32 = null;
    const b = a orelse 0;
    expect(b == 0);
    expect(@TypeOf(b) == f32);
}
```

`.?` is a shorthand for `orelse unreachable`. This is used for when you know it is impossible for an optional value to be null, and has the same implications as using `unreachable` normally.

```zig
test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    expect(b == c);
    expect(@TypeOf(c) == f32);
}
```

__Optional payloads__ work in many places.

Here we use an `if` optional payload; a and b are equivalent here.

```zig
test "if optional payload" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
    }

    const b: ?i32 = 5;
    if (b) |value| {
        
    }
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
    expect(sum == 6); // 3 + 2 + 1
}
```

Optional pointer and optional slice types do not take up any extra memory, compared to non-optional ones. This is because internally they use the 0 value of the pointer for `null`. This is how null pointers in zig work - they must be unwrapped to a non-optional before dereferencing, which stops null pointer dereferences from happening accidentally.

# Comptime, Generics

Zig allows the programmer to perform arbitrary calculations before runtime, using the `comptime` keyword:

```zig
test "comptime" {
    comptime {
        expect(fibonacci(10) == 5);
    }
}
```
```
error: encountered @panic at compile-time
    if (!ok) @panic("test failure");
             ^
.\tests.zig:373:15: note: called from here
        expect(fibonacci(10) == 5);
              ^
.\tests.zig:371:17: note: called from here
test "comptime" {
                ^
.\tests.zig:373:15: note: referenced here
        expect(fibonacci(10) == 5);
              ^
``` 

In zig, `type` is a type which can work at compile time. This allows us to easily achieve generics. Function parameters must have `comptime` as an attribute if they only work at compile time.

```zig
fn add(comptime T: type, a: T, b: T) T {
    return a + b;
}

test "generic add" {
    const result = add(f128, 100, -10);
    expect(result == 90);
    expect(@TypeOf(result) == f128);
}
```

Using a `var` function parameter allows a value of any type to be passed into it. Here, we make use of the `@TypeOf` built-in to perform comptime reflection.

```zig
fn mul(a: var, b: @TypeOf(a)) @TypeOf(a) {
    return a * b;
}

test "generic mul" {
    const result = mul(@as(f32, 20), -10);
    expect(result == -200);
    expect(@TypeOf(result) == f32);
}
```

`const` declarations at the global scope must have their values evaluated at compile time.

Types may be returned from functions, allowing for the creation of generic data types. It is convention to use PascalCase for functions that return types. It is important to note that these types are memoized.

```zig
fn LinkedList(comptime T: type) type {
    return struct {
        pub const Node = struct {
            prev: ?*Node,
            next: ?*Node,
            data: T,
        };
        first: ?*Node,
        last:  ?*Node,
        len:   usize,
    };
}

test "complex generic type" { 
    const list = LinkedList(i32) {
        .first = null,
        .last = null,
        .len = 0,
    };
    expect(@TypeOf(list) == LinkedList(i32));
}
```

Reflection may be used to restrict types.

```zig
fn sub(a: var, b: @TypeOf(a)) @TypeOf(a) {
    if (@typeInfo(@TypeOf(a)) != .Int) @compileError("Only ints supported!");
    return a - b;
}

test "restricted generics" {
    const x = sub(@as(f32, 100), 200);
}
```
```
error: Only ints supported!
    if (@typeInfo(@TypeOf(a)) != .Int) @compileError("Only ints supported!");
                                       ^
.\tests.zig:426:16: note: called from here
    const x = sub(@as(f32, 100), 200);
               ^
.\tests.zig:425:28: note: called from here
test "restricted generics" {
                           ^
```

Comptime also introduces the operators `++` and `**` for concatenating and repeating arrays and slices. These operators do not work at runtime.

```zig
test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    expect(new.len == 10);
}
```

```zig
const eql = @import("std").mem.eql;

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    expect(eql(
        u8,
        &memory,
        &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }
    ));
}
```

# Imports

The built-in function `@import` takes in a file, and gives you a struct type based on that file. All declarations labelled as `pub` (for public) will end up in this struct type, ready for use.

`@import("std")` is a special case in the compiler, and gives you access to the standard library. Other `@import`s will take in a file path, or a package name (more on packages in a later chapter).

Here, an `_` is used to discard the value of `std.fs.File`. This is used so that the compiler evaluates `std.fs.File`, allowing us to make sure that it exists.
```zig
test "import std" {
    const std = @import("std");
    _ = std.fs.File;
}
```


# Sentinel Termination

Arrays, slices and multi pointers may be terminated by a value of their child type. This is known as sentinel termination. These follow the syntax `[N:t]T`, `[:t]T`, and `[*:t]T`, where `t` is a value of the child type `T`.

An example of a sentinel terminated array. The built-in `@bitCast` is used to perform an unsafe bitwise type conversion. This shows us that the last element of the array is followed by a 0 byte.

```zig
test "sentinel termination" {
    const terminated = [3:0]u8 { 3, 2, 1 };
    expect(terminated.len == 3);
    expect(@bitCast([4]u8, terminated)[3] == 0); 
}
```

The types of string literals is `*const [N:0]u8`, where N is the length of the string. This allows string literals to coerce to sentinel terminated slices, and sentinel terminated multi pointers. Note: string literals are UTF-8 encoded.

```zig
test "string literal" {
    expect(@TypeOf("hello") == *const [5:0]u8);
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
    const a: [*:0]u8 = undefined;
    const b: [*]u8 = a;

    const c: [5:0]u8 = undefined;
    const d: [5]u8 = c;

    const e: [:10]f32 = undefined;
    const f = e;
}
```

# Allocators

The zig standard library provides a pattern for allocating memory, which allows the programmer to choose exactly how memory allocations are done within the standard library - no allocations happen behind your back in the standard library.

The most basic allocator is `std.heap.page_allocator`. Whenever this allocator makes an allocation it will ask your OS for an entire page of memory, which may be multiple kilobytes of memory even if only a single byte is used. As asking the OS for memory requires a system call, this is also extremely inefficient for speed.

Here, we allocate 100 bytes as a []u8. Notice how defer is used in conjunction with a free - this is a common pattern for memory management in zig.

```zig
const std = @import("std");

test "allocation" {
    const allocator = std.heap.page_allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    expect(memory.len == 100);
    expect(@TypeOf(memory) == []u8);
}
```

The `std.heap.FixedBufferAllocator` is an allocator that allocates memory into a fixed buffer, and does not make any heap allocations. This is useful when heap usage is not wanted, for example when writing a kernel. It may also be considered for performance reasons. It will give you the error `OutOfMemory` if it has run out of bytes.

```zig
test "fixed buffer allocator" {
    var buffer: [1000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buffer);
    var allocator = &fba.allocator;

    const memory = try allocator.alloc(u8, 100);
    defer allocator.free(memory);

    expect(memory.len == 100);
    expect(@TypeOf(memory) == []u8);
}
```

`std.heap.ArenaAllocator` takes in a child allocator, and allows you to allocate many times and only free once. Here, `.deinit()` is called on the arena which frees all memory. 

```zig
test "arena allocator" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    var allocator = &arena.allocator;

    const m1 = try allocator.alloc(u8, 1);
    const m2 = try allocator.alloc(u8, 10);
    const m3 = try allocator.alloc(u8, 100);
}
```

# Arraylist

The `std.ArrayList` is commonly used throughout Zig, and serves as a buffer which can change in size. `std.ArrayList(T)` is similar to C++'s `std::vector<T>` and Rust's `Vec<T>`. `.deinit()` frees all of the ArrayList's memory, which is another common pattern. The memory can be read from and written to via its slice field - `.items`.

```zig
test "arraylist" {
    var list = std.ArrayList(u8).init(std.heap.page_allocator);
    defer list.deinit();
    try list.append('H');
    try list.append('e');
    try list.append('l');
    try list.append('l');
    try list.append('o');
    try list.appendSlice(" World!");

    expect(std.mem.eql(u8, list.items, "Hello World!"));
}
```


# End Of Chapter 1
In the future we will cover things such as:
   - Anonymous structs
   - Areas of standard library
   - Zig fmt
   - Build system
   - C data types, libc, FFI, memory layout features
   - Zig cc, Zig c++, translate-c, cimport
   - Advanced comptime patterns and features
   - Async
   - SIMD
   - Inline and global assembly

Feedback and PRs are welcome.