---
title: "Chapter 0 - Getting Started"
weight: 1
---

# Welcome

[Zig](https://ziglang.org) is a general-purpose programming language and toolchain for maintaining __robust__, __optimal__, and __reusable__ software. 

Warning: the latest major release is 0.6 - Zig is still pre-1.0; usage in production is still not recommended and you may run into compiler bugs.

To follow this guide, we assume you have:
   * Prior experience programming
   * Some understanding of low-level programming

Knowing a language like C, C++, Rust, Go, Pascal or similar will be helpful for following this guide. You should have an editor, terminal and internet connection available to you. This guide is unofficial and unaffiliated with the project, and is designed to be read in order from the start.

# Installation

1.  Download a prebuilt master binary of zig from:
```
https://ziglang.org/download/
```

2. Add zig to your path

3. Verify your install with `zig version`

4. (optional) Install ZLS (unofficial) from:
```
https://github.com/zigtools/zls/
```

# Hello World

Create a file called `main.zig`, with the following contents:

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {}!\n", .{"World"});
}
```
###### (note: make sure your file is using spaces for indentation, LF line endings and UTF-8 encoding!)

Use `zig build-exe main.zig` to build. An executable called main will appear in your current working directory, which you may run. In this example `Hello, World!` will be written to stderr, and is assumed to never fail.