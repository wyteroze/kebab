// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const zlua = @import("zlua");
const log = @import("../log.zig").lua;
const Lua = zlua.Lua;

pub inline fn strEq(a: []const u8, b: []const u8) bool {
    return std.mem.eql(u8, a, b);
}

pub fn setObjectMetatable(l: *Lua) void {
    l.setMetatableRegistry("Object");
}

// Dumps the stack to the terminal
pub fn dumpStack(l: *Lua) void {
    const top = l.getTop();

    log.info("----- Lua stack ({d}) -----", .{ top });

    var i: i32 = top;
    while (i >= 1) : (i -= 1) {
        const t = l.typeOf(i);
        const rel_idx = i - (top + 1);
        const type_name = l.typeNameIndex(i);

        switch (t) {
            .string => log.info("[{d} / {d}] {s} '{s}'", .{ i, rel_idx, type_name, l.toString(i) catch "" }),
            .boolean => log.info("[{d} / {d}] {s} {}", .{ i, rel_idx, type_name, l.toBoolean(i) }),
            .number => log.info("[{d} / {d}] {s} {d}", .{ i, rel_idx, type_name, l.toNumber(i) catch 0 }),
            .table => log.info("[{d} / {d}] {s} table: {*}", .{ i, rel_idx, type_name, l.toPointer(i) }),
            .userdata => log.info("[{d} / {d}] {s} userdata({*})", .{ i, rel_idx, type_name, l.toPointer(i) }),
            else => log.info("[{d} / {d}] {s} {s}", .{ i, rel_idx, type_name, l.typeName(t) }),
        }
    }

    log.info("-----------------------------", .{});
}

pub fn OwnedHandle(comptime Fn: type) type {
    return struct {
        ctx: ?*anyopaque,
        func: ?*const Fn = null,
        destroy_fn: ?*const fn(ctx: ?*anyopaque) void = null,

        pub fn destroy(self: @This()) void {
            if (self.destroy_fn) |f| f(self.ctx);
        }
    };
}

pub fn Property(comptime T: type) type {
    return struct {
        name: []const u8,
        get: ?*const fn (l: *Lua, self: *T) i32 = null,
        set: ?*const fn (l: *Lua, self: *T) void = null
    };
}

pub fn dispatchIndex(comptime T: type, comptime props: []const Property(T), l: *Lua, self: *T, key: []const u8) ?i32 {
    inline for (props) |prop| {
        if (strEq(key, prop.name)) {
            if (prop.get) |g| { return g(l, self); }

            l.raiseErrorStr("'%s' is write-only, you may not read from it", .{ key.ptr });
            return 0;
        }
    }

    return null;
}

pub fn dispatchNewIndex(comptime T: type, comptime props: []const Property(T), l: *Lua, self: *T, key: []const u8) ?void {
    inline for (props) |prop| {
        if (strEq(key, prop.name)) {
            if (prop.set) |s| { s(l, self); return; }

            l.raiseError("'%s' is read-only, you may not assign to it", .{ key.ptr });
            return 0;
        }
    }

    return null;
}
