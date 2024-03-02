---
pagination_prev: build-system/generating-documentation
---


# ABI

An ABI _(application binary interface)_ is a standard, pertaining to:

- The in-memory layout of types (i.e. a type's size, alignment, offsets, and the
  layouts of its fields)
- The in-linker naming of symbols (e.g. name mangling)
- The calling conventions of functions (i.e. how a function call works at a
  binary level)

By defining these rules and not breaking them, an ABI is said to be stable, and
this can be used to, for example, reliably link together multiple libraries,
executables, or objects which were compiled separately (potentially on different
machines or using different compilers). This allows for FFI _(foreign function
interface)_ to take place, where we can share code between programming
languages.

Zig natively supports C ABIs for `extern` things; which C ABI is used depends on
the target you are compiling for (e.g. CPU architecture, operating system). This
allows for near-seamless interoperation with code that was not written in Zig;
the usage of C ABIs is standard amongst programming languages.

Zig internally does not use an ABI, meaning code should explicitly conform to a
C ABI where reproducible and defined binary-level behaviour is needed.
