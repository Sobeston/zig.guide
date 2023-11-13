# Many-item Pointers

Sometimes, you may have a pointer to an unknown amount of elements. `[*]T` is
the solution for this, which works like `*T` but also supports indexing syntax,
pointer arithmetic, and slicing. Unlike `*T`, it cannot point to a type which
does not have a known size. `*T` coerces to `[*]T`.

These many pointers may point to any amount of elements, including 0 and 1.
