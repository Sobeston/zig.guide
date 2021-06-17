---
title: "Chapter 4 - Working with C"
weight: 5
date: 2021-02-24 17:17:00
description: "Chapter 4 - Learn about how the Zig programming language makes use of C code. This tutorial covers C data types, FFI, building with C, translate-c and more!"
---

Zig has been designed from the ground up with C interop as a first class feature. In this section we will go over how this works.

# ABI

An ABI *(application binary interface)* is a standard, pertaining to:

- The in-memory layout of types (i.e. a type's size, alignment, offsets, and the layouts of its fields)
- The in-linker naming of symbols (e.g. name mangling)
- The calling conventions of functions (i.e. how a function call works at a binary level)

By defining these rules and not breaking them an ABI is said to be stable and this can be used to, for example, reliably link together multiple libraries, executables, or objects which were compiled separately (potentially on different machines, or using different compilers). This allows for FFI *(foreign function interface)* to take place, where we can share code between programming languages.

Zig natively supports C ABIs for `extern` things; which C ABI is used is dependant on the target which you are compiling for (e.g. CPU architecture, operating system). This allows for near-seamless interoperation with code that was not written in Zig; the usage of C ABIs is standard amongst programming languages.

Zig internally does not make use of an ABI, meaning code should explicitly conform to a C ABI where reproducible and defined binary-level behaviour is needed.

# C Primitive Types

Zig provides special `c_` prefixed types for conforming to the C ABI. These do not have fixed sizes, but rather change in size depending on the ABI being used.

| Type         | C Equivalent      | Minimum Size (bits) |
|--------------|-------------------|---------------------|
| c_short      | short             | 16                  |
| c_ushort     | unsigned short    | 16                  |
| c_int        | int               | 16                  |
| c_uint       | unsigned int      | 16                  |
| c_long       | long              | 32                  |
| c_ulong      | unsigned long     | 32                  |
| c_longlong   | long long         | 64                  |
| c_ulonglong  | unsigned longlong | 64                  |
| c_longdouble | long double       | N/A                 |
| c_void       | void              | N/A                 |

Note: C's void (and Zig's `c_void`) has an unknown non-zero size. Zig's `void` is a true zero-sized type.

# Calling conventions

Calling conventions describe how functions are called. This includes how arguments are supplied to the function (i.e. where they go - in registers or on the stack, and how), and how the return value is received.

In Zig, the attribute `callconv` may be given to a function. The calling conventions available may be found in [std.builtin.CallingConvention](https://ziglang.org/documentation/master/std/#std;builtin.CallingConvention). Here we make use of the cdecl calling convention.
```zig
fn add(a: u32, b: u32) callconv(.C) u32 {
    return a + b;
}
```

Marking your functions with the C calling convention is crucial when you're calling Zig from C.

# Extern Structs

Normal structs in Zig do not have a defined layout; `extern` structs are required for when you want the layout of your struct to match the layout of your C ABI.

Let's create an extern struct. This test should be run with `x86_64` with a `gnu` ABI, which can be done with `-target x86_64-native-gnu`.

```zig
const expect = @import("std").testing.expect;

const Data = extern struct {
    a: i32, b: u8, c: f32, d: bool, e: bool
};

test "hmm" {
    const x = Data{
        .a = 10005,
        .b = 42,
        .c = -10.5,
        .d = false,
        .e = true,
    };
    const z = @ptrCast([*]const u8, &x);

    try expect(@ptrCast(*const i32, z).* == 10005);
    try expect(@ptrCast(*const u8, z + 4).* == 42);
    try expect(@ptrCast(*const f32, z + 8).* == -10.5);
    try expect(@ptrCast(*const bool, z + 12).* == false);
    try expect(@ptrCast(*const bool, z + 13).* == true);
}
```

This is what the memory inside our `x` value looks like.

| Field | a  | a  | a  | a  | b  |    |    |    | c  | c  | c  | c  | d  | e  |    |    |
|-------|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
| Bytes | 15 | 27 | 00 | 00 | 2A | 00 | 00 | 00 | 00 | 00 | 28 | C1 | 00 | 01 | 00 | 00 |

Note how there are gaps in the middle and at the end - this is called "padding". The data in this padding is undefined memory, and won't always be zero.

As our `x` value is that of an extern struct, we could safely pass it into a C function expecting a `Data`, providing the C function was also compiled with the same `gnu` ABI and CPU arch.

# Alignment

For circuitry reasons, CPUs access primitive values at certain multiples in memory. This could mean for example that the address of an `f32` value must be a multiple of 4, meaning `f32` has an alignment of 4. This so-called "natural alignment" of primitive data types is dependent on CPU architecture. All alignments are powers of 2.

Data of a larger alignment also has the alignment of every smaller alignment; for example, a value which has an alignment of 16 also has an alignment of 8, 4, 2 and 1.

We can make specially aligned data by using the `align(x)` property. Here we are making data with a greater alignment.
```zig
const a1: u8 align(8) = 100;
const a2 align(8) = @as(u8, 100);
```
And making data with a lesser alignment. Note: Creating data of a lesser alignment isn't particularly useful.
```zig
const b1: u64 align(1) = 100;
const b2 align(1) = @as(u64, 100);
```

Like `const`, `align` is also a property of pointers.
```zig
test "aligned pointers" {
    const a: u32 align(8) = 5;
    try expect(@TypeOf(&a) == *align(8) const u32);
}
```

Let's make use of a function expecting an aligned pointer.

```zig
fn total(a: *align(64) const [64]u8) u32 {
    var sum: u32 = 0;
    for (a) |elem| sum += elem;
    return sum;
}

test "passing aligned data" {
    const x align(64) = [_]u8{10} ** 64;
    try expect(total(&x) == 640);
}
```

# Packed Structs

By default all struct fields in Zig are naturally aligned to that of [`@alignOf(FieldType)`](https://ziglang.org/documentation/master/#alignOf) (the ABI size), but without a defined layout. Sometimes you may want to have struct fields with a defined layout that do not conform to your C ABI. `packed` structs allow you to have extremely precise control of your struct fields, allowing you to place your fields on a bit-by-bit basis.

Inside packed structs, Zig's integers take their bit-width in space (i.e. a `u12` has an [`@bitSizeOf`](https://ziglang.org/documentation/master/#bitSizeOf) of 12, meaning it will take up 12 bits in the packed struct). Bools also take up 1 bit, meaning you can implement bit flags easily.

```zig
const MovementState = packed struct {
    running: bool,
    crouching: bool,
    jumping: bool,
    in_air: bool,
};

test "packed struct size" {
    try expect(@sizeOf(MovementState) == 1);
    try expect(@bitSizeOf(MovementState) == 4);
    const state = MovementState{
        .running = true,
        .crouching = true,
        .jumping = true,
        .in_air = true,
    };
}
```

Currently Zig's packed structs have some long withstanding compiler bugs, and do not currently work for many use cases.

# Bit Aligned Pointers

Similar to aligned pointers, bit aligned pointers have extra information in their type which informs how to access the data. These are necessary when the data is not byte-aligned. Bit alignment information is often needed to address fields inside of packed structs.

```zig
test "bit aligned pointers" {
    var x = MovementState{
        .running = false,
        .crouching = false,
        .jumping = false,
        .in_air = false,
    };

    const running = &x.running;
    running.* = true;

    const crouching = &x.crouching;
    crouching.* = true;

    try expect(@TypeOf(running) == *align(1:0:1) bool);
    try expect(@TypeOf(crouching) == *align(1:1:1) bool);

    try expect(@import("std").meta.eql(x, .{
        .running = true,
        .crouching = true,
        .jumping = false,
        .in_air = false,
    }));
}
```

# C Pointers

Up until now we have used the following kinds of pointers:

- single item pointers - `*T`
- many item pointers - `[*]T`
- slices - `[]T`

Unlike the aforementioned pointers, C pointers cannot deal with specially aligned data, and may point to the address `0`. C pointers coerce back and forth between integers, and also coerce to single and multi item pointers. When a C pointer of value `0` is coerced to a non-optional pointer, this is detectable illegal behaviour.

Outside of automatically translated C code, the usage of `[*c]` is almost always a bad idea, and should almost never be used.

# Translate-C

Zig provides the command `zig translate-c` for automatic translation from C source code.

Create the file `main.c` with the following contents.
```c
#include <stddef.h>

void int_sort(int* array, size_t count) {
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (array[j] > array[j+1]) {
                int temp = array[j];
                array[j] = array[j+1];
                array[j+1] = temp;
            }
        }
    }
}
```
Run the command `zig translate-c main.c` to get the equivalent Zig code output to your console (stdout). You may wish to pipe this into a file with `zig translate-c main.c > int_sort.zig` (warning for windows users: piping in powershell will produce a file with the incorrect encoding - use your editor to correct this).

In another file you could use `@import("int_sort.zig")` to make use of this function.

Currently the code produced may be unnecessarily verbose, though translate-c successfully translates most C code into Zig. You may wish to use translate-c to produce Zig code before editing it into more idiomatic code; a gradual transfer from C to Zig within a codebase is a supported use case.

# cImport

Zig's [`@cImport`](https://ziglang.org/documentation/master/#cImport) builtin is unique in that it takes in an expression, which can only take in [`@cInclude`](https://ziglang.org/documentation/master/#cInclude), [`@cDefine`](https://ziglang.org/documentation/master/#cDefine), and [`@cUndef`](https://ziglang.org/documentation/master/#cUndef). This works similarly to translate-c, translating C code to Zig under the hood.

[`@cInclude`](https://ziglang.org/documentation/master/#cInclude) takes in a path string, can adds the path to the includes list.

[`@cDefine`](https://ziglang.org/documentation/master/#cDefine) and [`@cUndef`](https://ziglang.org/documentation/master/#cUndef) define and undefine things for the import.

These three functions work exactly as you'd expect them to work within C code.

Similar to [`@import`](https://ziglang.org/documentation/master/#import) this returns a struct type with declarations. It is typically recommended to only use one instance of [`@cImport`](https://ziglang.org/documentation/master/#cImport) in an application to avoid symbol collisions; the types generated within one cImport will not be equivalent to those generated in another.

cImport is only available when linking libc.

# Linking libc

Linking libc can be done via the command line via `-lc`, or via `build.zig` using `exe.linkLibC();`. The libc used is that of the compilation's target; Zig provides libc for many targets.

# Zig cc, Zig c++

The Zig executable comes with Clang embedded inside it alongside libraries and headers required to cross compile for other operating systems and architectures.

This means that not only can `zig cc` and `zig c++` compile C and C++ code (with Clang-compatible arguments), but it can also do so while respecting Zig's target triple argument; the single Zig binary that you have installed has the power to compile for several different targets without the need to install multiple versions of the compiler or any addons. Using `zig cc` and `zig c++` also makes use of Zig's caching system to speed up your workflow.

Using Zig, one can easily construct a cross-compiling toolchain for languages which make use of a C and/or C++ compiler.

Some examples in the wild:

- [Using zig cc to cross compile LuaJIT to aarch64-linux from x86_64-linux](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html)

- [Using zig cc and zig c++ in combination with cgo to cross compile hugo from aarch64-macos to x86_64-linux, with full static linking](https://twitter.com/croloris/status/1349861344330330114)

- [Using zig build, zig cc, and zigmod to build snapraid](https://github.com/nektro/snapraid)

# End of Chapter 4

This chapter is incomplete. In the future it will contain things such as:
- Calling C code from Zig and vice versa
- Using `zig build` with a mixture of C and Zig code

Feedback and PRs are welcome.
