# Cross compilation

By default, Zig will compile for your combination of CPU and OS. This can be
overridden by `-target`. Let's compile our tiny hello world to a 64 bit arm
linux platform.

`zig build-exe .\tiny-hello.zig -O ReleaseSmall -fstrip -fsingle-threaded -target aarch64-linux`

[QEMU](https://www.qemu.org/) or similar may be used to conveniently test
executables made for foreign platforms.

Some CPU architectures that you can cross-compile for:

- `x86_64`
- `arm`
- `aarch64`
- `i386`
- `riscv64`
- `wasm32`

Some operating systems you can cross-compile for:

- `linux`
- `macos`
- `windows`
- `freebsd`
- `netbsd`
- `dragonfly`
- `UEFI`

Many other targets are available for compilation, but aren't as well tested as
of now. See
[Zig's support table](https://ziglang.org/learn/overview/#wide-range-of-targets-supported)
for more information; the list of well tested targets is slowly expanding.

As Zig compiles for your specific CPU by default, these binaries may not run on
other computers with slightly different CPU architectures. It may be useful to
instead specify a specific baseline CPU model for greater compatibility. Note:
choosing an older CPU architecture will bring greater compatibility, but means
you also miss out on newer CPU instructions; there is an efficiency/speed versus
compatibility trade-off here.

Let's compile a binary for a sandybridge CPU (Intel x86_64, circa 2011), so we
can be reasonably sure that someone with an x86_64 CPU can run our binary. Here
we can use `native` in place of our CPU or OS, to use our system's.

`zig build-exe .\tiny-hello.zig -target x86_64-native -mcpu sandybridge`

Details on what architectures, OSes, CPUs and ABIs (details on ABIs in the next
chapter) are available can be found by running `zig targets`. Note: the output
is long, and you may want to pipe it to a file, e.g.
`zig targets > targets.json`.
