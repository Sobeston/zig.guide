# CompileStep

The `std.build.CompileStep` type contains information required to build a
library, executable, object, or test.

Let's make use of our `Builder` and create a `CompileStep` using
`Builder.addExecutable`, which takes in a name and a path to the root of the
source.

<!--no_test-->

```zig
const Builder = @import("std").build.Builder;

pub fn build(b: *Builder) void {
    const exe = b.addExecutable(.{
        .name = "init-exe",
        .root_source_file = .{ .path = "src/main.zig" },
    });
    b.installArtifact(exe);
}
```
