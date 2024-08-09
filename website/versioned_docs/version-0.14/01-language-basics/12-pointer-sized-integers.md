# Pointer Sized Integers

`usize` and `isize` are given as unsigned and signed integers which are the same
size as pointers.

```zig
test "usize" {
    try expect(@sizeOf(usize) == @sizeOf(*u8));
    try expect(@sizeOf(isize) == @sizeOf(*u8));
}
```
