
---
title: "Chapter 5 - Zig for C Programmers"
weight: 2
date: 2020-09-29 20:57:00
description: "Chapter 5 - This is for those who are familiar with C but not with Zig"
---
This document does not cover Zig in detail or how to interface Zig with C. It gives some hints of potential problems and possible solutions when looking at Zig from a C perspective.

# Zig Source Code
- Do not use the tab character to indent. Spaces only.
- Use `\n` Unix style line endings.
- [Use UTF-8 encoding](https://ziglang.org/documentation/master/#Source-Encoding).

There is a [style guide](https://ziglang.org/documentation/master/#Style-Guide).

## Comments

- `//` [comments](https://ziglang.org/documentation/master/#Comments)
- `///` [doc comments](https://ziglang.org/documentation/master/#Doc-comments)
- `//!` [top level doc comments](https://ziglang.org/documentation/master/#Top-Level-Doc-Comments)

# C Preprocessor
Zig does not have a preprocessor.
## #error
The equivalent of `#error` is `@compileError()`. This is an [example](https://ziglang.org/documentation/master/#Local-Variables) amongst many in the documentation.

There is an example in [#ifdef](##ifdef) below. This shows the use of `@compileError` at the top level. `flag` could just as easily be imported from another (configuration) file. 

Zig does not have the equivalent of a command line `-D` option.  This can be achieved using the [Zig build system](https://ziglang.org/documentation/master/#Zig-Build-System). This requires something like:

```zig
comptime {
    const root = @import("root");
    if (!@hasDecl(root, "hello")) {
        @compileError("'root.hello' is not defined");
    }
    if (@TypeOf(root.hello) != []const u8) {
        @compileError("'root.hello' type must be '[]const u8'");
    }
}
```
There are examples within the source code for the Zig standard library.

## C Preprocessor incompatibilities
Zig cannot do preprocessor shenanigans involving token pasting:
```C
#define OPEN_BRACKET {
#define CLOSE_BRACKET }
```

```C
#define SOME_ARRAY(type, name) size_t name##count; size_t name##size; type *name##t
```

## C Preprocessor equivalents
Zig has the equivalent of simple C preprocessor directives resulting in equal or better output code sizes.
- imports, constants, functions and generics
- the `inline` keyword to force a function to be inlined at call sites (think function macros)
-  type checking
- an ability to evaluate code at [compile time](https://ziglang.org/documentation/master/#comptime)

 If Zig code is not referenced then that code does not appear in the generated output.

### #define *CONSTANT_VALUE*
```C
#define NUMBER 1
```
would be (with caveats):
```zig
pub const NUMBER = 1;
```
If the value is not needed outside of the current *.zig* file then `pub` is not required. If the compiler cannot determine the type at [compile time](https://ziglang.org/documentation/master/#comptime) then the type needs to be specified, say, a C int:
```zig
const NUMBER: c_int = 1;
```
The compiler will substitute `NUMBER` wherever it is used much like `#define`

And using caps `NUMBER` is not the preferred Zig [style](https://ziglang.org/documentation/master/#Style-Guide).

### #define *MACRO()*
```C
#define NN_FLAGS(x) ((x) & 0xf0)
```
in Zig
```zig
pub inline fn NN_FLAGS(x: c_int) c_int { return (x & 0xf0); }
```
### #ifdef 
This demonstrates the Zig equivalent of `#ifdef` `#else` `#endif`.
```zig
const std = @import("std");
const assert = std.debug.assert;

const flag = false;  // Change to true to avoid error

usingnamespace if (flag)
    struct {
        pub fn demo() bool {
            return true;
        }
    }
else
    @compileError("flag cannot be false");

test "compile time error" {
    if (flag) {
        assert(demo() == true);
    }
}
```
`struct` is a namespace hence `pub`  is required to expose the `demo()` function outside the `struct` namespace. [`usingnamespace`](https://ziglang.org/documentation/master/#usingnamespace) brings the published contents of `struct` into the top level.

Zig does not have a -D command line directive so any variables or constants used have to be defined in Zig source somewhere. Or in the build system (TODO) if that is being used.

## #include
The direct equivalent of `#include "foo.h"`  would be `usingnamespace @import("foo.zig")` meaning that all symbols declared `pub` in *"foo.zig"* would be available.

- [`usingnamespace`](https://ziglang.org/documentation/master/#usingnamespace)
- [`@import`](https://ziglang.org/documentation/master/#import)

If [`usingnamespace`](https://ziglang.org/documentation/master/#usingnamespace) is not used then the import would be via (the preferred) `const foo = @import("foo.zig")`

The `pub` keyword is for visibility with other Zig source files. Not to be confused with the [`export`](https://ziglang.org/documentation/master/#Exporting-a-C-Library) keyword which is makes a symbol visible in the generated object file.

# Header Files
Zig has no concept of header files. Everything is a *.zig* file.

## Code Guards
Code guards regularly used in C header files to prevent repeated includes and circular references:
```C
#ifndef FOO_H
#define FOO_H
/*
   ... header code goes here
*/
#endif
```
- Code guards are not required with Zig
- Zig does not have header files
- Zig files [@import](https://ziglang.org/documentation/master/#import) other Zig files
- Zig allows multiple repeat imports and circular imports (assuming no symbolic link craziness).

This example shows *foo.zig* importing *bar.zig* which imports *foo.zig*:

*foo.zig*
```zig
const  std = @import("std");  // the Zig standard library
const  assert = std.debug.assert;

const  bar = @import("bar.zig");
const  bar2 = @import("bar.zig"); // repeated import Ok

pub  fn  foobar() u8 {
    return  'f';
}

test  "import test" {
    assert(bar.barfoo() == bar2.barfoo());
}
```
*bar.zig*
```zig
// import foo which imports bar ...
const foo = @import("foo.zig"); // circular import Ok

pub fn barfoo() u8 {
    return localFunction();
}

fn localFunction() u8 {
    return foo.foobar();
}
```
Running `zig test foo.zig` demonstrates circular and repeat imports.
```sh
$ zig test foo.zig
All 1 tests passed.
```
# Error Messages
- Zig's error messages are not numbered.
- Zig is a young language so using a search engine for the meaning of an error can be fraught.
- Zig's error messages are usually good enough to find the error though a good knowledge of Zig may be required to fix said error.

# Package Path
This is Ok in C. `#include` from anywhere within the file system.
```C
#include "../../../include/includeme.h"
```
But an import in Zig has to be kept within the package path or the compiler will issue the error:
`import of file outside package path`

This can easily be resolved by the creative use of symbolic links. But beware of circular import references through the those links.

*package path*? TODO what is it?

# Note: Zig Compiler

If the Zig compiler crashes on your system then check your system's [tier](https://ziglang.org/#Tier-System).  This also applies to Zig compiled executables and libs that use the Zig Standard Library.

In event of a compiler crash try using the Zig compiler from a Tier 1 system and cross-compile to the target system where the generated code may not have issues.

# Note: Zig Standard Library.
If the targeted system is not [Tier 1](https://ziglang.org/#Tier-System) then there *may* be issues with the Zig's standard library. In this instance avoid using Zig's standard library at *runtime* 

With only `comptime` usage of the Zig standard library the resultant code would be consider Free Standing and possibly on a higher tier.

# zig translate-c
Using Zig's translate-c functionality is useful for converting C to Zig. It can be verbose and may not translate all C. `#define` constants are replaced by their actual values.

# TODO:

- `comptime` and why not to worry about apparently extraneous code
- `extern` and why it is not needed except when interfacing to C code.
- `typedef` Zig's types are first class. `const mytype = uint16;`
- `zig translate-c` is your friend
- what `zig translate-c` misses and how to fix
- `#ifdef` `#else` `#endif` `usingnamespace if struct{} else struct{}`
- `zig build-obj`
- `varargs` and `printf` not available with Zig. Zig's `std.fmt` shows how.