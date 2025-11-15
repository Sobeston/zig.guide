// hide-start
const std = @import("std");
// hide-end
const MyByteList = struct {
    data: [100]u8 = undefined,
    items: []u8 = &[_]u8{},

    fn appendWrite(self: *MyByteList, buf: []const u8) !usize {
        if (self.items.len + buf.len > self.data.len) {
            return error.EndOfBuffer;
        }

        std.mem.copyForwards(u8, self.data[self.items.len .. self.items.len + buf.len], buf);
        self.items = self.data[0 .. self.items.len + buf.len];
        return buf.len;
    }

    pub fn writer(self: *MyByteList) std.io.GenericWriter(
        *MyByteList,
        error{EndOfBuffer}, // <-- REQUIRED NOW
        appendWrite,
    ) {
        return .{ .context = self };
    }
};

test "custom writer" {
    var bytes = MyByteList{};

    const w = bytes.writer();
    try w.writeAll("Hello");
    try w.writeAll(" Writer!");

    try std.testing.expectEqualSlices(u8, bytes.items, "Hello Writer!");
}
