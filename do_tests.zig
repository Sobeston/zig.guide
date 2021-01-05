const std = @import("std");

const chapter_0 = @import("test-out/test-c0.zig");
const chapter_1 = @import("test-out/test-c1.zig");
const chapter_2 = @import("test-out/test-c2.zig");
const chapter_3 = @import("test-out/test-c3.zig");
const chapter_4 = @import("test-out/test-c4.zig");
const chapter_5 = @import("test-out/test-c5.zig");

comptime {
    _ = std.testing.refAllDecls(@This());
}
