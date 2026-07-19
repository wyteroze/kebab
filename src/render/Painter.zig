// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");
const engine_types = @import("../types.zig");
const RenderTarget = @import("RenderTarget.zig").RenderTarget;
const UIPainter = @import("UIPainter.zig");
const Font = @import("../ui/Font.zig").Font;
const Color = @import("../Color.zig").Color;
const Vec2 = @import("../script/objects/Vec2.zig").Vec2;

const Rect = types.Rect;

/// This is passed on a canvas' OnPaint event.
pub const Painter = struct {
    pub const lua_ref = true;
    pub const lua_name = "Painter";
    pub const hidden = .{ "target", "origin", "clip", "font" };

    target: *RenderTarget,
    origin: engine_types.Vec2,
    clip: ?Rect,
    font: *Font,

    pub fn Line(self: *Painter, a: Vec2, b: Vec2, color: Color) void {
        UIPainter.line(self.target, self.localX(a), self.localY(a), self.localX(b), self.localY(b), color.color, self.clip);
    }

    pub fn FillRect(self: *Painter, pos: Vec2, size: Vec2, color: Color) void {
        UIPainter.rect(self.target, self.localX(pos), self.localY(pos), toI32(size.vec[0]), toI32(size.vec[1]), color.color, self.clip);
    }

    pub fn FillTriangle(self: *Painter, a: Vec2, b: Vec2, c: Vec2, color: Color) void {
        UIPainter.fillTriangle(self.target, self.localX(a), self.localY(a), self.localX(b), self.localY(b), self.localX(c), self.localY(c), color.color, self.clip);
    }

    pub fn FillCircle(self: *Painter, center: Vec2, radius: f32, color: Color) void {
        UIPainter.circle(self.target, self.localX(center), self.localY(center), toI32(radius), color.color, self.clip);
    }

    pub fn Wedge(self: *Painter, center: Vec2, radius: f32, start: f32, end: f32, color: Color) void {
        UIPainter.wedge(self.target, self.localX(center), self.localY(center), toI32(radius), start, end, color.color, self.clip);
    }

    pub fn Text(self: *Painter, pos: Vec2, str: []const u8, color: Color, scale: ?u32) void {
        UIPainter.text(self.target, self.font, self.localX(pos), self.localY(pos), str, color.color, self.clip, scale orelse 1);
    }

    inline fn localX(self: *Painter, v: Vec2) i32 { return toI32(self.origin[0] + v.vec[0]); }
    inline fn localY(self: *Painter, v: Vec2) i32 { return toI32(self.origin[1] + v.vec[1]); }
};

inline fn toI32(v: f32) i32 { return @intFromFloat(@trunc(v)); }
