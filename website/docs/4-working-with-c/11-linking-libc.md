# Linking libc

Linking libc can be done via the command line via `-lc`, or via `build.zig`
using `exe.linkLibC();`. The libc used is that of the compilation's target; Zig
provides libc for many targets.
