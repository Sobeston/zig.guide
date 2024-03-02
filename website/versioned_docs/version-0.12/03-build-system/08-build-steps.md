# Build steps

Build steps are a way of providing tasks for the build runner to execute. Let's
create a build step, and make it the default. When you run `zig build` this will
output `Hello!`.

<!--no_test-->

```zig
const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    const step = b.step("task", "do something");
    step.makeFn = myTask;
    b.default_step = step;
}

fn myTask(self: *std.build.Step, progress: *std.Progress.Node) !void {
    std.debug.print("Hello!\n", .{});
    _ = progress;
    _ = self;
}
```

We called `b.installArtifact(exe)` earlier - this adds a build step which tells
the builder to build the executable.
