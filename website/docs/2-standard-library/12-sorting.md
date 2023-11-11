# Sorting

The standard library provides utilities for in-place sorting slices. Its basic
usage is as follows.

```zig
test "sorting" {
    var data = [_]u8{ 10, 240, 0, 0, 10, 5 };
    std.mem.sort(u8, &data, {}, comptime std.sort.asc(u8));
    try expect(eql(u8, &data, &[_]u8{ 0, 0, 5, 10, 10, 240 }));
    std.mem.sort(u8, &data, {}, comptime std.sort.desc(u8));
    try expect(eql(u8, &data, &[_]u8{ 240, 10, 10, 5, 0, 0 }));
}
```

[`std.sort.asc`](https://ziglang.org/documentation/master/std/#A;std:sort.asc)
and [`.desc`](https://ziglang.org/documentation/master/std/#A;std:sort.desc)
create a comparison function for the given type at comptime; if non-numerical
types should be sorted, the user must provide their own comparison function.

[`std.sort.sort`](https://ziglang.org/documentation/master/std/#A;std:sort.sort)
has a best case of O(n), and an average and worst case of O(n*log(n)).
