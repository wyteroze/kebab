// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("../../types.zig");
const shared = @import("../shared.zig");

pub const Vec2 = struct {
    pub const name = "Vec2Object";
    pub const hidden = .{ "vec" };
    pub const operators = .{
        .add = "add",
        .sub = "sub",
        .mul = "mul",
        .div = "div",
        .unm = "unm"
    };

    vec: types.Vec2,

    pub fn init(x: f32, y: f32) Vec2 {
        return .{ .vec = types.Vec2{ x, y } };
    }

    pub fn getX(self: Vec2) f32 { return self.vec[0]; }
    pub fn setX(self: *Vec2, v: f32) void { self.vec[0] = v; }
    pub fn getY(self: Vec2) f32 { return self.vec[1]; }
    pub fn setY(self: *Vec2, v: f32) void { self.vec[1] = v; }

    pub fn add(self: Vec2, other: Vec2) Vec2 { return .{ .vec = self.vec + other.vec }; }
    pub fn sub(self: Vec2, other: Vec2) Vec2 { return .{ .vec = self.vec - other.vec }; }
    pub fn mul(self: Vec2, other: Vec2) Vec2 { return .{ .vec = self.vec * other.vec }; }
    pub fn div(self: Vec2, other: Vec2) Vec2 { return .{ .vec = self.vec / other.vec }; }
    pub fn unm(self: Vec2) Vec2 { return .{ .vec = -self.vec }; }

    pub fn format(self: Vec2, writer: *std.Io.Writer) !void {
        try writer.print("({d}, {d})", .{
            shared.cleanFloatingPoint(self.vec[0]),
            shared.cleanFloatingPoint(self.vec[1]),
        });
    }
};
