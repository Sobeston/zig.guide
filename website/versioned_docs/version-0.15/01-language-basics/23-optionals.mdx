import CodeBlock from "@theme/CodeBlock";

import OptionalsFind from "!!raw-loader!./23.optionals-find.zig";
import OptionalsOrelse from "!!raw-loader!./23.optionals-orelse.zig";
import OptionalsOrelseUnreachable from "!!raw-loader!./23.optionals-orelse-unreachable.zig";
import OptionalsIfPayload from "!!raw-loader!./23.optionals-if-payload.zig";
import OptionalsWhileCapture from "!!raw-loader!./23.optionals-while-capture.zig";

# Optionals

Optionals use the syntax `?T` and are used to store the data
[`null`](https://ziglang.org/documentation/master/#null), or a value of type
`T`.

<CodeBlock language="zig">{OptionalsFind}</CodeBlock>

Optionals support the `orelse` expression, which acts when the optional is
[`null`](https://ziglang.org/documentation/master/#null). This unwraps the
optional to its child type.

<CodeBlock language="zig">{OptionalsOrelse}</CodeBlock>

`.?` is a shorthand for `orelse unreachable`. This is used for when you know it
is impossible for an optional value to be null, and using this to unwrap a
[`null`](https://ziglang.org/documentation/master/#null) value is detectable
illegal behaviour.

<CodeBlock language="zig">{OptionalsOrelseUnreachable}</CodeBlock>

Both `if` expressions and `while` loops support taking optional values as conditions,
allowing you to "capture" the inner non-null value.

Here we use an `if` optional payload capture; a and b are equivalent here.
`if (b) |value|` captures the value of `b` (in the cases where `b` is not null),
and makes it available as `value`. As in the union example, the captured value
is immutable, but we can still use a pointer capture to modify the value stored
in `b`.

<CodeBlock language="zig">{OptionalsIfPayload}</CodeBlock>

And with `while`:

<CodeBlock language="zig">{OptionalsWhileCapture}</CodeBlock>

Optional pointer and optional slice types do not take up any extra memory
compared to non-optional ones. This is because internally they use the 0 value
of the pointer for `null`.

This is how null pointers in Zig work - they must be unwrapped to a non-optional
before dereferencing, which stops null pointer dereferences from happening
accidentally.
