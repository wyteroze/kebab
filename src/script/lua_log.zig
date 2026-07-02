// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const zlua = @import("zlua");
const log = @import("../log.zig").lua;
const Lua = zlua.Lua;
var allocator: std.mem.Allocator = undefined;

pub fn doLog(comptime level: std.log.Level, l: *Lua) i32 {
    const nargs = l.getTop();
    var buf = std.ArrayList(u8).empty;
    defer buf.deinit(allocator);

    for (1..@as(usize, @intCast(nargs + 1))) |i| {
        _ = l.getGlobal("tostring");
        l.pushValue(@as(i32, @intCast(i)));
        l.call(.{ .args = 1, .results = 1 });

        const str = l.toString(-1) catch "";

        if (i > 1) buf.appendSlice(allocator, "\t") catch {};
        buf.appendSlice(allocator, str) catch {};

        l.pop(1);
    }

    l.pop(nargs);

    switch (level) {
        .debug => log.debug("{s}", .{ buf.items }),
        .info => log.info("{s}", .{ buf.items }),
        .warn => log.warn("{s}", .{ buf.items }),
        .err => log.err("{s}", .{ buf.items }),
    }

    return 0;
}

pub fn printLog(l: *Lua) i32 { return doLog(.info, l); }
pub fn warnLog(l: *Lua) i32 { return doLog(.warn, l); }

// we do NOT override `error()` as things get funky
// if we do, and we already handle errors and output
// them to where we want in ScriptEngine.

pub fn register(l: *Lua, a: std.mem.Allocator) !void {
    allocator = a;

    // print
    l.pushFunction(zlua.wrap(printLog));
    l.setGlobal("print");

    // warn
    l.pushFunction(zlua.wrap(warnLog));
    l.setGlobal("warn");
}
