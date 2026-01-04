// hide-start
const expect = @import("std").testing.expect;

//hide-end
test "coercion" {
    const a: [*:0]u8 = undefined;
    const b: [*]u8 = a;

    const c: [5:0]u8 = undefined;
    const d: [5]u8 = c;

    const e: [:0]f32 = undefined;
    const f: []f32 = e;

    _ = .{ b, d, f }; //ignore unused
}
