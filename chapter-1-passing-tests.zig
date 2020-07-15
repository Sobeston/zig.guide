const expect = @import("std").testing.expect;

test "if statement" {
    const a = true;
    var x: u16 = 0;
    if (a) {
        x += 1;
    } else {
        x += 2;
    }
    expect(x == 1);
}

test "if statement expression" {
    const a = true;
    var x: u16 = 0;
    x += if (a) 1 else 2;
    expect(x == 1);
}

test "while" {
    var i: u8 = 2;
    while (i < 100) {
        i *= 2;
    }
    expect(i == 128);
}

test "while with continue expression" {
    var sum: u8 = 0;
    var i: u8 = 1;
    while (i <= 10) : (i += 1) {
        sum += i;
    }
    expect(sum == 55);
}

test "while with continue" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) continue;
        sum += i;
    }
    expect(sum == 4);
}

test "while with break" {
    var sum: u8 = 0;
    var i: u8 = 0;
    while (i <= 3) : (i += 1) {
        if (i == 2) break;
        sum += i;
    }
    expect(sum == 1);
}

test "for" {
    //character literals are equivalent to integer literals
    const string = [_]u8{ 'a', 'b', 'c' };

    for (string) |character, index| {}

    for (string) |character| {}

    for (string) |_, index| {}

    for (string) |_| {}
}

fn addFive(x: u32) u32 {
    return x + 5;
}

test "function" {
    const y = addFive(0);
    expect(@TypeOf(y) == u32);
    expect(y == 5);
}

fn fibonacci(n: u16) u16 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

test "function recursion" {
    const x = fibonacci(10);
    expect(x == 55);
}

test "defer" {
    var x: i16 = 5;
    {
        defer x += 2;
        expect(x == 5);
    }
    expect(x == 7);
}

test "multi defer" {
    var x: f32 = 5;
    {
        defer x += 2;
        defer x /= 2;
    }
    expect(x == 4.5);
}

const FileOpenError = error {
    AccessDenied,
    OutOfMemory,
    FileNotFound,
};

const AllocationError = error {OutOfMemory};

test "coerce error from a subset to a superset" {
    const err: FileOpenError = AllocationError.OutOfMemory;
    expect(err == FileOpenError.OutOfMemory);
}

test "error union" {
    const maybe_error: AllocationError!u16 = 10;
    const no_error = maybe_error catch 0;

    expect(@TypeOf(no_error) == u16);
    expect(no_error == 10);
}

fn failingFunction() error{Oops}!void {
    return error.Oops;
}

test "returning an error" {
    failingFunction() catch |err| {
        expect(err == error.Oops);
        return;
    };
}

fn failFn() error{Oops}!void {
    try failingFunction();
}

test "try" {
    failFn() catch |err| {
        expect(err == error.Oops);
        return;
    };
}

var problems: u32 = 98;

fn failFnCounter() error{Oops}!void {
    errdefer problems += 1;
    try failingFunction();
}

test "errdefer" {
    failFnCounter() catch |err| {
        expect(err == error.Oops);
        expect(problems == 99);
        return;
    };
}

fn createFile() !void {
    return error.AccessDenied;
}

test "inferred error set" {
    //type coercion successfully takes place
    const x: error{AccessDenied}!void = createFile();
}

test "switch statement" {
    var x: i8 = 10;
    switch (x) {
        -1...1 => {
            x = -x;
        },
        10, 100 => {
            //special considerations must be made
            //when dividing signed integers
            x = @divExact(x, 10);
        },
        else => {},
    }
    expect(x == 1);
}

test "switch expression" {
    var x: i8 = 10;
    x = switch (x) {
        -1...1 => -x,
        10, 100 => @divExact(x, 10),
        else => x,
    };
    expect(x == 1);
}



test "out of bounds, no safety" {
    @setRuntimeSafety(false);
    const a = [3]u8{ 1, 2, 3 };
    var index: u8 = 5;
    const b = a[index];
}

fn asciiToUpper(x: u8) u8 {
    return switch (x) {
        'a'...'z' => x + 'A' - 'a',
        'A'...'Z' => x,
        else => unreachable,
    };
}

test "unreachable switch" {
    expect(asciiToUpper('a') == 'A');
    expect(asciiToUpper('A') == 'A');
}

fn increment(num: *u8) void {
    num.* += 1;
}

test "pointers" {
    var x: u8 = 1;
    increment(&x);
    expect(x == 2);
}

test "usize" {
    expect(@sizeOf(usize) == @sizeOf(*u8));
    expect(@sizeOf(isize) == @sizeOf(*u8));
}

fn total(values: []const u8) usize {
    var count: usize = 0;
    for (values) |v| count += v;
    return count;
}
test "slices" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array[0..3];
    expect(total(slice) == 6);
}

test "slices 2" {
    const array = [_]u8{1, 2, 3, 4, 5};
    const slice = array[0..3];
    expect(@TypeOf(slice) == *const [3]u8);
}

test "slices 3" {
    var array = [_]u8{1, 2, 3, 4, 5};
    var slice = array[0..];
}

const Value = enum(u2) { Zero, One, Two };

test "enum ordinal value" {
    expect(@enumToInt(Value.Zero) == 0);
    expect(@enumToInt(Value.One) == 1);
    expect(@enumToInt(Value.Two) == 2);
}

const Value2 = enum(u32) {
    Hundred = 100,
    Thousand = 1000,
    Million = 1000000,
    Next,
};

test "set enum ordinal value" {
    expect(@enumToInt(Value2.Hundred) == 100);
    expect(@enumToInt(Value2.Thousand) == 1000);
    expect(@enumToInt(Value2.Million) == 1000000);
    expect(@enumToInt(Value2.Next) == 1000001);
}

const Suit = enum {
    clubs,
    spades,
    diamonds,
    hearts,
    pub fn isClubs(self: Suit) bool {
        return self == Suit.clubs;
    }
};

test "enum method" {
   expect(Suit.spades.isClubs() == Suit.isClubs(.spades));
}

const Mode = enum {
    var count: u32 = 0;
    on,
    off,
};

test "hmm" {
    Mode.count += 1;
    expect(Mode.count == 1);
}

const Vec3 = struct {
    x: f32, y: f32, z: f32
};

test "struct usage" {
    const my_vector = Vec3{
        .x = 0,
        .y = 100,
        .z = 50,
    };
}

const Vec4 = struct {
    x: f32, y: f32, z: f32 = 0, w: f32 = undefined
};

test "struct defaults" {
    const my_vector = Vec4{
        .x = 25,
        .y = -50,
    };
}

const Stuff = struct {
    x: i32,
    y: i32,
    fn swap(self: *Stuff) void {
        const tmp = self.x;
        self.x = self.y;
        self.y = tmp;
    }
};

test "automatic dereference" {
    var thing = Stuff{ .x = 10, .y = 20 };
    thing.swap();
    expect(thing.x == 20);
    expect(thing.y == 10);
}

const Tag = enum { a, b, c };

const Tagged = union(Tag) { a: u8, b: f32, c: bool };

test "switch on tagged union" {
    var value = Tagged{ .b = 1.5 };
    switch (value) {
        .a => |*byte| byte.* += 1,
        .b => |*float| float.* *= 2,
        .c => |*b| b.* = !b.*,
    }
    expect(value.b == 3);
}

test "integer widening" {
    const a: u8 = 250;
    const b: u16 = a;
    const c: u32 = b;
    expect(c == a);
}

test "@intCast" {
    const x: u64 = 200;
    const y = @intCast(u8, x);
    expect(@TypeOf(y) == u8);
}

test "well defined overflow" {
    var a: u8 = 255;
    a +%= 1;
    expect(a == 0);
}

test "float coercion" {
    const a: f16 = 0;
    const b: f128 = a;
    const c: f32 = b;
    expect(c == a);
}

test "int-float conversion" {
    const a: i32 = 0;
    const b = @intToFloat(f32, a);
    const c = @floatToInt(i32, b);
    expect(c == a);
}

test "labelled blocks" {
    const count = blk: {
        var sum: u32 = 0;
        var i: u32 = 0;
        while (i < 10) : (i += 1) sum += i;
        break :blk sum;
    };
    expect(count == 45);
    expect(@TypeOf(count) == u32);
}

test "nested continue" {
    var count: usize = 0;
    outer: for ([_]i32{ 1, 2, 3, 4, 5, 6, 7, 8 }) |_| {
        for ([_]i32{ 1, 2, 3, 4, 5 }) |_| {
            count += 1;
            continue :outer;
        }
    }
    expect(count == 8);
}

fn rangeHasNumber(begin: usize, end: usize, number: usize) bool {
    var i = begin;
    return while (i < end) : (i += 1) {
        if (i == number) {
            break true;
        }
    } else false;
}

test "while loop expression" {
    expect(rangeHasNumber(0, 10, 3));
}

test "optional" {
    var found_index: ?usize = null;
    const data = [_]i32{1, 2, 3, 4, 5, 6, 7, 8, 12};
    for (data) |v, i| {
        if (v == 10) found_index = i;
    }
    expect(found_index == null);
}

test "orelse" {
    var a: ?f32 = null;
    var b = a orelse 0;
    expect(b == 0);
    expect(@TypeOf(b) == f32);
}

test "orelse unreachable" {
    const a: ?f32 = 5;
    const b = a orelse unreachable;
    const c = a.?;
    expect(b == c);
    expect(@TypeOf(c) == f32);
}

test "if optional payload capture" {
    const a: ?i32 = 5;
    if (a != null) {
        const value = a.?;
    }

    const b: ?i32 = 5;
    if (b) |value| {
        
    }
}

var numbers_left: u32 = 4;
fn eventuallyNullSequence() ?u32 {
    if (numbers_left == 0) return null;
    numbers_left -= 1;
    return numbers_left;
}

test "while null capture" {
    var sum: u32 = 0;
    while (eventuallyNullSequence()) |value| {
        sum += value;
    }
    expect(sum == 6); // 3 + 2 + 1
}

test "comptime blocks" {
    var x = comptime fibonacci(10);

    var y = comptime blk: {
        break :blk fibonacci(10);
    };
}

test "comptime_int" {
    const a = 12;
    const b = a + 10;

    const c: u4 = a;
    const d: f32 = b;
}

test "branching on types" {
    const a = 5;
    const b: if (a < 10) f32 else i32 = 5;
}

fn Matrix(
    comptime T: type,
    comptime width: comptime_int,
    comptime height: comptime_int,
) type {
    return [height][width]T;
}

test "returning a type" {
    expect(Matrix(f32, 4, 4) == [4][4]f32);
}

fn addSmallInts(comptime T: type, a: T, b: T) T {
    return switch (@typeInfo(T)) {
        .ComptimeInt => a + b,
        .Int => |info| if (info.bits <= 16)
            a + b
        else
            @compileError("ints too large"),
        else => @compileError("only ints accepted"),
    };
}

test "typeinfo switch" {
    const x = addSmallInts(u16, 20, 30);
    expect(@TypeOf(x) == u16);
    expect(x == 50);
}

fn getBiggerInt(comptime T: type) type {
    return @Type(.{ .Int = .{
        .bits = @typeInfo(T).Int.bits + 1, 
        .is_signed = @typeInfo(T).Int.is_signed 
    }});
}

test "@Type" {
    expect(getBiggerInt(u8) == u9);
    expect(getBiggerInt(i31) == i32);
}

fn Vec(
    comptime count: comptime_int,
    comptime T: type,
) type {
    return struct {
        data: [count]T,
        const Self = @This();

        fn abs(self: Self) Self {
            var tmp = Self{ .data = undefined };
            for (self.data) |elem, i| {
                tmp.data[i] = if (elem < 0)
                    -elem
                else
                    elem;
            }
            return tmp;
        }

        fn init(data: [count]T) Self {
            return Self{ .data = data };
        }
    };
}

const eql = @import("std").mem.eql;

test "generic vector" {
    const x = Vec(3, f32).init([_]f32{ 10, -10, 5 });
    const y = x.abs();
    expect(eql(f32, &y.data, &[_]f32{ 10, 10, 5 }));
}

fn plusOne(x: anytype) @TypeOf(x) {
    return x + 1;
}

test "inferred function parameter" {
    expect(plusOne(@as(u32, 1)) == 2);
}

test "++" {
    const x: [4]u8 = undefined;
    const y = x[0..];

    const a: [6]u8 = undefined;
    const b = a[0..];

    const new = y ++ b;
    expect(new.len == 10);
}

test "**" {
    const pattern = [_]u8{ 0xCC, 0xAA };
    const memory = pattern ** 3;
    expect(eql(
        u8,
        &memory,
        &[_]u8{ 0xCC, 0xAA, 0xCC, 0xAA, 0xCC, 0xAA }
    ));
}

test "inline for" {
    const types = [_]type{ i32, f32, u8, bool };
    var sum: usize = 0;
    inline for (types) |T| sum += @sizeOf(T);
    expect(sum == 10);
}

test "anonymous struct literal" {
    const Point = struct {x: i32, y: i32};
    
    var pt: Point = .{
        .x = 13,
        .y = 67,
    };
    expect(pt.x == 13);
    expect(pt.y == 67);
}

test "fully anonymous struct" {
    dump(.{
        .int = @as(u32, 1234),
        .float = @as(f64, 12.34),
        .b = true,
        .s = "hi",
    });
}

fn dump(args: anytype) void {
    expect(args.int == 1234);
    expect(args.float == 12.34);
    expect(args.b);
    expect(args.s[0] == 'h');
    expect(args.s[1] == 'i');
}

test "tuple" {
    const values = .{ 
        @as(u32, 1234),
        @as(f64, 12.34),
        true,
        "hi"
    } ++ .{ false } ** 2;
    expect(values[0] == 1234);
    expect(values[4] == false);
    inline for (values) |v, i| {
        if (i != 2) continue;
        expect(v);
    }
    expect(values.len == 6);
    expect(values.@"3"[0] == 'h');
}

test "sentinel termination" {
    const terminated = [3:0]u8 { 3, 2, 1 };
    expect(terminated.len == 3);
    expect(@bitCast([4]u8, terminated)[3] == 0); 
}

test "string literal" {
    expect(@TypeOf("hello") == *const [5:0]u8);
}

test "C string" {
    const c_string: [*:0]const u8 = "hello";
    var array: [5]u8 = undefined;

    var i: usize = 0;
    while (c_string[i] != 0) : (i += 1) {
        array[i] = c_string[i];
    }
}

test "coercion" {
    const a: [*:0]u8 = undefined;
    const b: [*]u8 = a;

    const c: [5:0]u8 = undefined;
    const d: [5]u8 = c;

    const e: [:10]f32 = undefined;
    const f = e;
}

test "sentinel terminated slicing" {
    var x = [_:0]u8{255} ** 3;
    const y = x[0..3:0];
}

const meta = @import("std").meta;
const Vector = meta.Vector;

test "vector add" {
    const x: Vector(4, f32) = .{ 1, -10, 20, -1 };
    const y: Vector(4, f32) = .{ 2, 10, 0, 1 };
    const z = x + y;
    expect(meta.eql(z, Vector(4, f32){ 3, 0, 20, 0 }));
}

test "vector indexing" {
    const x: Vector(4, u8) = .{ 255, 0, 255, 0 };
    expect(x[0] == 255);
}

test "vector * scalar" {
    const x: Vector(3, f32) = .{ 12.5, 37.5, 2.5 };
    const y = x * @splat(3, @as(f32, 2));
    expect(meta.eql(y, Vector(3, f32){ 25, 75, 5 }));
}

const len = @import("std").mem.len;

test "vector looping" {
    const x = Vector(4, u8){ 255, 0, 255, 0 };
    var sum = blk :{
        var tmp: u10 = 0;
        var i: u8 = 0;
        while (i < len(x)) : (i += 1) tmp += x[i];
        break :blk tmp;
    };
    expect(sum == 510);
}

const arr: [4]f32 = @Vector(4, f32){ 1, 2, 3, 4 };
