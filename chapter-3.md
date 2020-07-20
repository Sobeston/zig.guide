---
title: "Chapter 3 - Build system"
weight: 4
date: 2020-07-17 07:02:20
description: "Chapter 3 - Ziglang's build system in detail."
---

# Build Modes  

Zig provides four build modes, with debug being the default as it produces the shortest compile times.

|               | Runtime Safety | Optimizations |
|---------------|----------------|---------------|
| Debug         | Yes            | No            |
| Release-Safe  | Yes            | Yes, Speed    |
| Release-Small | No             | Yes, Size     |
| Release-Fast  | No             | Yes, Speed    |

These may be enabled in `zig run` and `zig test` with the arguments `--release-safe`, `--release-small` and `--release-fast`.

Users are recommended to develop their software with runtime safety enabled, despite its small speed disadvantage.

# Outputting an Executable

The commands `zig build-exe`, `zig build-lib`, and `zig build-obj` can be used to output executables, libraries and objects, respectively. These commands take in a source file and arguments.

Some common arguments:
- `--single-threaded`, which asserts the binary is single-threaded. This will turn thread safety measures such as mutexes into no-ops.
- `--strip`, which removes debug info from the binary.
- `--dynamic`, which is used in conjunction with `zig build-lib` to output a dynamic/shared library.

Let's create a tiny hello world. Save this as `tiny-hello.zig`, and run `zig build-exe --release-small --strip --singlethreaded`. Currently for `x86_64-windows`, this produces a 2.5KiB executable.

```zig
const std = @import("std");

pub fn main() void {
    std.io.getStdOut().writeAll(
        "Hello World!"
    ) catch unreachable;
}
```

# Cross compilation

By default, Zig will compile for your combination of CPU and OS. This can be overridden by `-target`. Let's compile our tiny hello world to a 64 bit arm linux platform.

`zig build-exe .\tiny-hello.zig --release-small --strip --single-threaded -target aarch64-linux`

[QEMU](https://www.qemu.org/) or similar may be used to conveniently test executables made for foreign platforms.

Some CPU architectures that you can cross-compile for:
- `x86_64`
- `arm`
- `aarch64`
- `i386`
- `riscv64`
- `wasm32`

Some operating systems you can cross-compile for:
- `linux`
- `macosx`
- `windows`
- `freebsd`
- `netbsd`
- `dragonfly`
- `UEFI`

Many other targets are available for compilation, but aren't as well tested as of now. See [Zig's support table](https://ziglang.org/#Wide-range-of-targets-supported) for more information; the list of well tested targets is slowly expanding.

As Zig compiles for your specific CPU by default, these binaries may not run on other computers with slightly different CPU architectures. It may be useful to instead specify a specific baseline CPU model for greater compatibility. Note: choosing an older CPU architecture will bring greater compatibility, but means you also miss out on newer CPU instructions; there is an efficiency/speed versus compatibility trade-off here.

Let's compile a binary for a sandybridge CPU (Intel x86_64, circa 2011), so we can be reasonably sure that someone with an x86_64 CPU can run our binary. Here we can use `native` in place of our CPU or OS, to use our system's.

`zig build-exe .\tiny-hello.zig -target x86_64-native -mcpu sandybridge`

Details on what architectures, OSes, CPUs and ABIs (details on ABIs in the next chapter) are available can be found by running `zig targets`. Note: the output is long, and you may want to pipe it to a file, e.g. `zig targets > targets.json`.

# Zig Build

The `zig build` command allows users to compile based on a `build.zig` file. `zig init-exe` and `zig-init-lib` can be used to give you a baseline project.

Let's use `zig init-exe` inside a new folder. This is what you will find.
```
.
├── build.zig
└── src
    └── main.zig
```
`build.zig` contains our build script. The *build runner* will use this `pub fn build` function as its entry point - this is what is executed when you run `zig build`.

```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();

    const exe = b.addExecutable("init-exe", "src/main.zig");
    exe.setTarget(target);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

`main.zig` contains our executable's entry point.

```zig
const std = @import("std");

pub fn main() anyerror!void {
    std.debug.warn("All your codebase are belong to us.\n", .{});
}
```

Upon using the `zig build` command, the executable will appear in the install path. Here we have not specified an install path, so the executable will be saved in `./zig-cache/bin`.

# Builder

Zig's `std.build.Builder` type contains the information used by the build runner. This includes information such as:

- the build target
- the release mode
- locations of libraries
- the install path
- build steps

# LibExeObjStep

The `std.build.LibExeObjStep` type contains information required to build a library, executable, object, or test.

Let's make use of our `Builder` and create a `LibExeObjStep` using `Builder.addExecutable`, which takes in a name and a path to the root of the source.

```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable("program", "src/main.zig");
    exe.install();
}
```

# Build steps

Build steps are a way of providing tasks for the build runner to  execute. Let's create a build step, and make it the default. When you run `zig build` this will output `Hello!`. 

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const step = b.step("task", "do something");
    step.makeFn = myTask;
    b.default_step = step;
}

fn myTask(self: *std.build.Step) !void {
    std.debug.print("Hello!\n", .{});
}
```

We called `exe.install()` earlier - this adds a build step which tells the builder to build the executable.

# End of Chapter 3

This chapter is incomplete. In the future it will contain information on how to make use of `zig build`.

The next chapter is planned to cover usage with C. Feedback and PRs are welcome.