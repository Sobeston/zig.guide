# cImport

Zig's [`@cImport`](https://ziglang.org/documentation/master/#cImport) builtin is
unique in that it takes in an expression, which can only take in
[`@cInclude`](https://ziglang.org/documentation/master/#cInclude),
[`@cDefine`](https://ziglang.org/documentation/master/#cDefine), and
[`@cUndef`](https://ziglang.org/documentation/master/#cUndef). This works
similarly to translate-c, translating C code to Zig under the hood.

[`@cInclude`](https://ziglang.org/documentation/master/#cInclude) takes in a
path string and adds the path to the includes list.

[`@cDefine`](https://ziglang.org/documentation/master/#cDefine) and
[`@cUndef`](https://ziglang.org/documentation/master/#cUndef) define and
undefine things for the import.

These three functions work exactly as you'd expect them to work within C code.

Similar to [`@import`](https://ziglang.org/documentation/master/#import), this
returns a struct type with declarations. It is typically recommended to only use
one instance of [`@cImport`](https://ziglang.org/documentation/master/#cImport)
in an application to avoid symbol collisions; the types generated within one
cImport will not be equivalent to those generated in another.

cImport is only available when linking libc.
