---
title: "Chapter 4 - Working with C"
weight: 4
date: 2020-07-20 10:56:00
description: "Chapter 4 - Learn about how the zig programming language makes use of C code. This tutorial covers C data types, FFI, building with C, translate-c and more!"
---

Zig has been designed from the ground up with C interop as a first class feature. In this section we will go over how this works.

# The C ABI

The C ABI *(application binary interface)* is a set of standards, pertaining to:

- The sizes of types
- The memory layout of structs
- How types are aligned (details on alignment later)
- How function calls work, i.e. calling conventions

The C ABI that you're using is dependant on what CPU architecture you're using, and the standard you're using (e.g. GNU, MSVC, etc).

The point in an ABI is so that machine code can interoperate with other machine code, independent of what compilers or programming languages are used to build each part of code.

Zig internally does not make use of an ABI, meaning code should explicitly conform to the C ABI where that behaviour is desired.

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
fn add(a: u32, b: u32) callconv (.C) u32 {
    return a + b;
}
```

Using a calling convention is crucial when you're calling C code from Zig, or vice versa.

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

    expect(@ptrCast(*const i32, z).* == 10005);
    expect(@ptrCast(*const u8, z + 4).* == 42);
    expect(@ptrCast(*const f32, z + 8).* == -10.5);
    expect(@ptrCast(*const bool, z + 12).* == false);
    expect(@ptrCast(*const bool, z + 13).* == true);
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
    expect(@TypeOf(&a) == *align(8) const u32);
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
    expect(total(&x) == 640);
}
```

# C Pointers

Up until now we have used the following kinds of pointers:

- single item pointers - `*T`
- multi item pointers - `[*]T`
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
        for (int j = 0; i < count - i - 1; j++) {
            int temp = array[j];
            array[j] = array[j+1];
            array[j+1] = temp;
        }
    }
}
```
Run the command `zig translate-c main.c` to get the equivalent zig code output to your console (stdout). You may wish to pipe this into a file with `zig translate-c main.c > int_sort.zig` (warning for windows users: piping in powershell will produce a file with the incorrect encoding - use your editor to correct this).

In another file you could use `@import("int_sort.zig")` to make use of this function.

Currently the code produced may be unnecessarily verbose, though translate-c successfully translates most C code into Zig. You may wish to use translate-c to produce Zig code before editing it into more idiomatic code; a gradual transfer from C to Zig within a codebase is a supported use case.

# End of Chapter 4

This chapter is incomplete. In the future it will contain things such as:
- Packed structs, bit aligned pointers
- Cimports
- Calling C code from Zig and vice versa
- Zig cc, Zig c++
- Using `zig build` with a mixture of C and Zig code

Feedback and PRs are welcome.
