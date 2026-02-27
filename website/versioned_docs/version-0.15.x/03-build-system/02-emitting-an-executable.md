# Emitting an Executable

The commands `zig build-exe`, `zig build-lib`, and `zig build-obj` can be used
to output executables, libraries, and objects, respectively. These commands take
in a source file and arguments.

Some common arguments:

- `-fsingle-threaded`, which asserts the binary is single-threaded. This will
  turn thread-safety measures such as mutexes into no-ops.
- `-fstrip`, which removes debug info from the binary.
- `--dynamic`, which is used in conjunction with `zig build-lib` to output a
  dynamic/shared library.

Let's create a tiny hello world. Save this as `tiny-hello.zig`, and run
`zig build-exe tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded`.

We'll print "Hello World" using Zig's wrappers around the OS write syscall

Linux:

```zig
const std = @import("std");

pub fn main() void {
    const msg = "Hello World\n";
    _ = std.os.linux.write(1, msg, msg.len);
}

```

Windows:

```zig
const std = @import("std");

pub fn main() void {
    const msg = "Hello World\n";
    const handle = std.os.windows.GetStdHandle(std.os.windows.STD_OUTPUT_HANDLE) catch return;
    _ = std.os.windows.WriteFile(handle, msg, null) catch return;
}
```
