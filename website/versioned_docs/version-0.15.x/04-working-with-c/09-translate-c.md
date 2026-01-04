# Translate-C

Zig provides the command `zig translate-c` for automatic translation from C
source code.

Create the file `main.c` with the following contents.

```c
#include <stddef.h>

void int_sort(int* array, size_t count) {
    for (int i = 0; i < count - 1; i++) {
        for (int j = 0; j < count - i - 1; j++) {
            if (array[j] > array[j+1]) {
                int temp = array[j];
                array[j] = array[j+1];
                array[j+1] = temp;
            }
        }
    }
}
```

Run the command `zig translate-c main.c` to get the equivalent Zig code output
to your console (stdout). You may wish to pipe this into a file with
`zig translate-c main.c > int_sort.zig` (warning for Windows users: piping in
PowerShell will produce a file with the incorrect encoding - use your editor to
correct this).

In another file you could use `@import("int_sort.zig")` to use this function.

Currently the code produced may be unnecessarily verbose, though translate-c
successfully translates most C code into Zig. You may wish to use translate-c to
produce Zig code before editing it into more idiomatic code; a gradual transfer
from C to Zig within a codebase is a supported use case.
