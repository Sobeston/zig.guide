import CodeBlock from "@theme/CodeBlock";

import IntegerWidening from "!!raw-loader!./18.integer-widening.zig";
import IntegerCasting from "!!raw-loader!./18.integer-casting.zig";
import IntegerSafeOverflow from "!!raw-loader!./18.integer-safe-overflow.zig";

# Integer Rules

Zig supports hex, octal and binary integer literals.

```zig
const decimal_int: i32 = 98222;
const hex_int: u8 = 0xff;
const another_hex_int: u8 = 0xFF;
const octal_int: u16 = 0o755;
const binary_int: u8 = 0b11110000;
```

Underscores may also be placed between digits as a visual separator.

```zig
const one_billion: u64 = 1_000_000_000;
const binary_mask: u64 = 0b1_1111_1111;
const permissions: u64 = 0o7_5_5;
const big_address: u64 = 0xFF80_0000_0000_0000;
```

"Integer Widening" is allowed, which means that integers of a type may coerce to
an integer of another type, providing that the new type can fit all of the
values that the old type can.

<CodeBlock language="zig">{IntegerWidening}</CodeBlock>

If you have a value stored in an integer that cannot coerce to the type that you
want, [`@intCast`](https://ziglang.org/documentation/master/#intCast) may be
used to explicitly convert from one type to the other. If the value given is out
of the range of the destination type, this is detectable illegal behaviour.

<CodeBlock language="zig">{IntegerCasting}</CodeBlock>

Integers, by default, are not allowed to overflow. Overflows are detectable
illegal behaviour. Sometimes, being able to overflow integers in a well-defined
manner is a wanted behaviour. For this use case, Zig provides overflow
operators.

| Normal Operator | Wrapping Operator |
| --------------- | ----------------- |
| +               | +%                |
| -               | -%                |
| \*              | \*%               |
| +=              | +%=               |
| -=              | -%=               |
| \*=             | \*%=              |

<CodeBlock language="zig">{IntegerSafeOverflow}</CodeBlock>
