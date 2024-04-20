---
pagination_next: working-with-c/abi
---


# Generating Documentation

The Zig compiler comes with automatic documentation generation. This can be
invoked by adding `-femit-docs` to your `zig build-{exe, lib, obj}` or `zig run`
command. This documentation is saved into `./docs`, as a small static website.

Zig's documentation generation makes use of _doc comments_ which are similar to
comments, using `///` instead of `//`, and preceding globals.

Here we will save this as `x.zig` and build documentation for it with
`zig build-lib -femit-docs x.zig -target native-windows`. There are some things
to take away here:

- Only things that are public with a doc comment will appear
- Blank doc comments may be used
- Doc comments can make use of subset of markdown
- Things will only appear inside generated documentation if the compiler
  analyses them; you may need to force analysis to happen to get things to
  appear.

<!--no_test-->

```zig
const std = @import("std");
const w = std.os.windows;

///**Opens a process**, giving you a handle to it. 
///[MSDN](https://docs.microsoft.com/en-us/windows/win32/api/processthreadsapi/nf-processthreadsapi-openprocess)
pub extern "kernel32" fn OpenProcess(
    ///[The desired process access rights](https://docs.microsoft.com/en-us/windows/win32/procthread/process-security-and-access-rights)
    dwDesiredAccess: w.DWORD,
    ///
    bInheritHandle: w.BOOL,
    dwProcessId: w.DWORD,
) callconv(w.WINAPI) ?w.HANDLE;

///spreadsheet position
pub const Pos = struct{
    ///row
    x: u32,
    ///column
    y: u32,
};

pub const message = "hello!";

//used to force analysis, as these things aren't otherwise referenced.
comptime {
    _ = OpenProcess;
    _ = Pos;
    _ = message;
}

//Alternate method to force analysis of everything automatically, but only in a test build:
test "Force analysis" {
    comptime {
        std.testing.refAllDecls(@This());
    }
}
```

When using a `build.zig` this may be invoked by setting the `emit_docs` field to
`.emit` on a `CompileStep`. We can create a build step to generate docs as
follows and invoke it with `$ zig build docs`.

<!--no_test-->

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const mode = b.standardReleaseOptions();

    const lib = b.addStaticLibrary("x", "src/x.zig");
    lib.setBuildMode(mode);
    lib.install();

    const tests = b.addTest("src/x.zig");
    tests.setBuildMode(mode);

    const test_step = b.step("test", "Run library tests");
    test_step.dependOn(&tests.step);

    //Build step to generate docs:
    const docs = b.addTest("src/x.zig");
    docs.setBuildMode(mode);
    docs.emit_docs = .emit;
    
    const docs_step = b.step("docs", "Generate docs");
    docs_step.dependOn(&docs.step);
}
```

This generation is experimental and often fails with complex examples. This is
used by the
[standard library documentation](https://ziglang.org/documentation/master/std/).

When merging error sets, the left-most error set's documentation strings take
priority over the right. In this case, the doc comment for `C.PathNotFound` is
the doc comment provided in `A`.

<!--no_test-->

```zig
const A = error{
    NotDir,

    /// A doc comment
    PathNotFound,
};
const B = error{
    OutOfMemory,

    /// B doc comment
    PathNotFound,
};

const C = A || B;
```
