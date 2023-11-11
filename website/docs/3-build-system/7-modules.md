# Modules

The Zig build system has the concept of modules, which are other source files
written in Zig. Let's make use of a module.

From a new folder, run the following commands.

```
zig init-exe
mkdir libs
cd libs
git clone https://github.com/Sobeston/table-helper.git
```

Your directory structure should be as follows.

```
.
├── build.zig
├── libs
│   └── table-helper
│       ├── example-test.zig
│       ├── README.md
│       ├── table-helper.zig
│       └── zig.mod
└── src
    └── main.zig
```

To your newly made `build.zig`, add the following lines.

<!--no_test-->

```zig
const table_helper = b.addModule("table-helper", .{
    .source_file = .{ .path = "libs/table-helper/table-helper.zig" }
});
exe.addModule("table-helper", table_helper);
```

Now when run via `zig build`,
[`@import`](https://ziglang.org/documentation/master/#import) inside your
`main.zig` will work with the string "table-helper". This means that main has
the table-helper package. Packages (type
[`std.build.Pkg`](https://ziglang.org/documentation/master/std/#std;build.Pkg))
also have a field for dependencies of type `?[]const Pkg`, which is defaulted to
null. This allows you to have packages which rely on other packages.

Place the following inside your `main.zig` and run `zig build run`.

<!--no_test-->

```zig
const std = @import("std");
const Table = @import("table-helper").Table;

pub fn main() !void {
    try std.io.getStdOut().writer().print("{}\n", .{
        Table(&[_][]const u8{ "Version", "Date" }){
            .data = &[_][2][]const u8{
                .{ "0.7.1", "2020-12-13" },
                .{ "0.7.0", "2020-11-08" },
                .{ "0.6.0", "2020-04-13" },
                .{ "0.5.0", "2019-09-30" },
            },
        },
    });
}
```

This should print this table to your console.

```
Version Date       
------- ---------- 
0.7.1   2020-12-13 
0.7.0   2020-11-08 
0.6.0   2020-04-13 
0.5.0   2019-09-30
```

Zig does not yet have an official package manager. Some unofficial experimental
package managers however do exist, namely
[gyro](https://github.com/mattnite/gyro) and
[zigmod](https://github.com/nektro/zigmod). The `table-helper` package is
designed to support both of them.

Some good places to find packages include: [astrolabe.pm](https://astrolabe.pm),
[zpm](https://zpm.random-projects.net/),
[awesome-zig](https://github.com/nrdmn/awesome-zig/), and the
[zig tag on GitHub](https://github.com/topics/zig).
