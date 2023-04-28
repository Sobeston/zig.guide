const std = @import("std");

pub const chapter_0 = @import("test-out/test-c0.zig");
pub const chapter_1 = @import("test-out/test-c1.zig");
pub const chapter_2 = @import("test-out/test-c2.zig");
pub const chapter_3 = @import("test-out/test-c3.zig");
pub const chapter_4 = @import("test-out/test-c4.zig");
// pub const chapter_5 = @import("test-out/test-c5.zig"); -- disabled: no async support in compiler

comptime {
    std.testing.refAllDecls(@This());
}
