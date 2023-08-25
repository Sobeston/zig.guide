---
title: "Глава 0 — Начало работы"
weight: 1
date: 2023-04-28 18:00:00
description: "Zighelp — Руководство по языку программирования Zig. Начните установку и работу с Zig здесь."
---

## TODO actual translation (this is just a showcase)
## TODO перевода пока нет, это только показательный пример

## Добро пожаловать

[Zig](https://ziglang.org) — это язык программирования общего назначения и инструмент для создания __надёжного__, __оптимального__ и __переиспользуемого__ ПО.

Внимание: последняя значительная версия 0.11 - Zig всё ещё не дошёл до 1.0; Вы можете столкнуться с багами компилятора, не рекомендуем использовать его в производстве.

To follow this guide, we assume you have:
   * Prior experience programming
   * Some understanding of low-level programming concepts

Knowing a language like C, C++, Rust, Go, Pascal or similar will be helpful for following this guide. You should have an editor, terminal and internet connection available to you. This guide is unofficial and unaffiliated with the Zig Software Foundation, and is designed to be read in order from the start.

## Installation

**This guide assumes you're using a master build** of Zig as opposed to the latest major release, which means downloading a binary from the site or compiling from source; **the version of Zig in your package manager is likely outdated**. This guide does not support Zig 0.10.1.

1.  Download and extract a prebuilt master binary of Zig from https://ziglang.org/download/.

2. Add Zig to your path
   - linux, macos, bsd

      Add the location of your Zig binary to your `PATH` environment variable. For an installation, add `export PATH=$PATH:~/zig` or similar to your `/etc/profile` (system-wide) or `$HOME/.profile`. If these changes do not apply immediately, run the line from your shell.
   - windows

      a) System wide (admin powershell)

      ```powershell
      [Environment]::SetEnvironmentVariable(
         "Path",
         [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\your-path\zig-windows-x86_64-your-version",
         "Machine"
      )
      ```

      b) User level (powershell)

      ```powershell
      [Environment]::SetEnvironmentVariable(
         "Path",
         [Environment]::GetEnvironmentVariable("Path", "User") + ";C:\your-path\zig-windows-x86_64-your-version",
         "User"
      )
      ```

      Close your terminal and create a new one.

3. Verify your install with `zig version`. The output should look something like
```
$ zig version
0.11.0-dev.2777+b95cdf0ae
```

4. (optional, third party) For completions and go-to-definition in your editor, install the Zig Language Server from https://github.com/zigtools/zls/.

5. (optional) Join a [Zig community](https://github.com/ziglang/zig/wiki/Community).

## Hello World

Create a file called `main.zig`, with the following contents:

```zig
const std = @import("std");

pub fn main() void {
    std.debug.print("Hello, {s}!\n", .{"World"});
}
```

!!! note "note: make sure your file is using spaces for indentation, LF line endings and UTF-8 encoding!"

Use `zig run main.zig` to build and run it. In this example `Hello, World!` will be written to stderr, and is assumed to never fail.
