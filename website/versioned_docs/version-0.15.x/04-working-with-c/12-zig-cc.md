# Zig cc, Zig c++

The Zig executable comes with Clang embedded inside it alongside libraries and
headers required to cross-compile for other operating systems and architectures.

This means that not only can `zig cc` and `zig c++` compile C and C++ code (with
Clang-compatible arguments), but it can also do so while respecting Zig's target
triple argument; the single Zig binary that you have installed has the power to
compile for several different targets without the need to install multiple
versions of the compiler or any addons. Using `zig cc` and `zig c++` also makes
use of Zig's caching system to speed up your workflow.

Using Zig, one can easily construct a cross-compiling toolchain for languages
that use a C and/or C++ compiler.

Some examples in the wild:

- [Using zig cc to cross compile LuaJIT to aarch64-linux from x86_64-linux](https://andrewkelley.me/post/zig-cc-powerful-drop-in-replacement-gcc-clang.html)

- [Using zig cc and zig c++ in combination with cgo to cross compile hugo from aarch64-macos to x86_64-linux, with full static linking](https://twitter.com/croloris/status/1349861344330330114)
