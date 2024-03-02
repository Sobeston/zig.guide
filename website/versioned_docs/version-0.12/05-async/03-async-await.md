# Async / Await

Similar to how well formed code has a suspend for every resume, each `async`
function invocation with a return value must be matched with an `await`. The
value yielded by `await` on the async frame corresponds to the function's
return.

You may notice that `func3` here is a normal function (i.e. it has no suspend
points - it is not an async function). Despite this, `func3` can work as an
async function when called from an async invocation; the calling convention of
`func3` doesn't have to be changed to async - `func3` can be of any calling
convention.

```zig
fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}
```

Using `await` on an async frame of a function which may suspend is only possible
from async functions. As such, functions that use `await` on the frame of an
async function are also considered async functions. If you can be sure that the
potential suspend doesn't happen, `nosuspend await` will stop this from
happening.
