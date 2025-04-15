// hide-start
const std = @import("std");
const eql = std.mem.eql;
const expect = std.testing.expect;
// hide-end
test "split iterator" {
    const text = "robust, optimal, reusable, maintainable, ";
    var iter = std.mem.splitSequence(u8, text, ", ");
    try expect(eql(u8, iter.next().?, "robust"));
    try expect(eql(u8, iter.next().?, "optimal"));
    try expect(eql(u8, iter.next().?, "reusable"));
    try expect(eql(u8, iter.next().?, "maintainable"));
    try expect(eql(u8, iter.next().?, ""));
    try expect(iter.next() == null);
}
