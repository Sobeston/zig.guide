const expect = @import("std").testing.expect;

var foo: i32 = 1;

test "suspend with no resume" {
    var frame = async func(); //1
    _ = frame;
    try expect(foo == 2);     //4
}

fn func() void {
    foo += 1;                 //2
    suspend {}                //3
    foo += 1;                 //never reached!
}

var bar: i32 = 1;

test "suspend with resume" {
    var frame = async func2();  //1
    resume frame;               //4
    try expect(bar == 3);       //6
}

fn func2() void {
    bar += 1;                   //2
    suspend {}                  //3
    bar += 1;                   //5
}

fn func3() u32 {
    return 5;
}

test "async / await" {
    var frame = async func3();
    try expect(await frame == 5);
}

fn add(a: i32, b: i32) i64 {
    return a + b;
}

test "@Frame" {
    var frame: @Frame(add) = async add(1, 2);
    try expect(await frame == 3);
}

fn double(value: u8) u9 {
    suspend {
        resume @frame();
    }
    return value * 2;
}

test "@frame 1" {
    var f = async double(1);
    try expect(nosuspend await f == 2);
}

const std = @import("std");

fn callLater(comptime laterFn: fn () void, ms: u64) void {
    suspend {
        wakeupLater(@frame(), ms);
    }
    laterFn();
}

fn wakeupLater(frame: anyframe, ms: u64) void {
    std.time.sleep(ms * std.time.ns_per_ms);
    resume frame;
}

fn alarm() void {
    std.debug.print("Time's Up!\n", .{});
}

test "@frame 2" {
    nosuspend callLater(alarm, 1000);
}

fn zero(comptime x: anytype) x {
    return 0;
}

fn awaiter(x: anyframe->f32) f32 {
    return nosuspend await x;
}

test "anyframe->T" {
    var frame = async zero(f32);
    try expect(awaiter(&frame) == 0);
}

