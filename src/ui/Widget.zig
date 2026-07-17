// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const Color = @import("../Color.zig").Color;
const Font = @import("Font.zig").Font;
const TextSize = @import("Font.zig").TextSize;
const types = @import("../types.zig");
const Vec2 = @import("../script/objects/Vec2.zig").Vec2;
const Callback = @import("../script/shared.zig").Callback;
const marshal = @import("../script/reflect/marshal.zig");
const Handle = marshal.Handle;
const Diagnostic = @import("../script/shared.zig").Diagnostic;


pub const ButtonState = enum { normal, hover, pressed };
pub const ButtonData = struct {
    state: ButtonState,
    bg: Color,
    border: ?Color = null,
    content: TextContent,
    on_click: ?Callback = null
};
const TextContent = struct {
    text: []const u8 = "",
    color: Color,
    font: ?*Font = null,
};
pub const PanelData  = struct { bg: Color, border: ?Color = null };
pub const LabelData  = struct { content: TextContent };

pub const AbsRect = struct { x: f32, y: f32, w: f32, h: f32 };
pub const Anchor = enum {
    TopLeft,
    Top,
    TopRight,
    Left,
    Center,
    Right,
    BottomLeft,
    Bottom,
    BottomRight,

    pub fn factor(self: Anchor) types.Vec2 {
        return switch (self) {
            .TopLeft => .{ 0, 0 },   .Top => .{ 0.5, 0 },   .TopRight => .{ 1, 0 },
            .Left    => .{ 0, 0.5 }, .Center => .{ 0.5, 0.5 }, .Right   => .{ 1, 0.5 },
            .BottomLeft => .{ 0, 1 }, .Bottom => .{ 0.5, 1 }, .BottomRight => .{ 1, 1 },
        };
    }
};

pub const WidgetKind = enum { panel, label, button };

pub const Widget = struct {
    pub const lua_ref = true;
    pub const lua_name = "WidgetInstance";
    pub const hidden = .{ "data", "resolved", "allocator", "diagnostic", "anchor", "offset", "size", "visible" };
    diagnostic: Diagnostic = .{},
    allocator: std.mem.Allocator,

    anchor: Anchor,
    offset: types.Vec2,
    size: types.Vec2,
    visible: bool = true,
    resolved: AbsRect = .{ .x=0, .y=0, .w=0, .h=0 },   // cached every frame

    data: union(WidgetKind) {
        panel: PanelData,
        label: LabelData,
        button: ButtonData,

        pub fn luaName(self: @This()) []const u8 {
            return switch (self) { .panel => "Panel", .label => "Label", .button => "Button" };
        }
    },

    pub fn getAnchor(self: Widget) Anchor { return self.anchor; }
    pub fn setAnchor(self: *Widget, v: Anchor) void { self.anchor = v; }

    pub fn getOffset(self: Widget) Vec2 { return .{ .vec = self.offset }; }
    pub fn setOffset(self: *Widget, v: Vec2) void { self.offset = v.vec; }
    pub fn getSize(self: Widget) Vec2 { return .{ .vec = self.size }; }
    pub fn setSize(self: *Widget, v: Vec2) void { self.size = v.vec; }
    pub fn getVisible(self: Widget) bool { return self.visible; }
    pub fn setVisible(self: *Widget, v: bool) void { self.visible = v; }

    pub fn getFont(self: Widget) ?Handle(Font) {
        const font = switch (self.data) {
            .label => |l| l.content.font,
            .button => |b| b.content.font,
            .panel => null,
        };
        return .{ .ptr = @constCast(font orelse return null) };
    }

    pub fn getBg(self: Widget) ?Color {
        return switch (self.data) { .panel => |p| p.bg, .button => |b| b.bg, .label => null };
    }
    pub fn setBg(self: *Widget, v: Color) !void {
        switch (self.data) {
            .panel => |*p| p.bg = v,
            .button => |*b| b.bg = v,
            .label => return error.WidgetHasNoBackground,
        }
    }

    pub fn getBorder(self: Widget) ?Color {
        return switch (self.data) { .panel => |p| p.border, .button => |b| b.border, .label => null };
    }
    pub fn setBorder(self: *Widget, v: Color) !void {
        switch (self.data) {
            .panel => |*p| p.border = v,
            .button => |*b| b.border = v,
            .label => return error.WidgetHasNoBorder,
        }
    }

    pub fn getText(self: Widget) ?[]const u8 {
        return switch (self.data) { .label => |l| l.content.text, .button => |b| b.content.text, .panel => null };
    }
    pub fn getTextColor(self: Widget) ?Color {
        return switch (self.data) { .label => |l| l.content.color, .button => |b| b.content.color, .panel => null };
    }

    pub fn setText(self: *Widget, v: []const u8) !void {
        const c = self.textContent() orelse return error.WidgetHasNoText;
        self.allocator.free(c.text);
        c.text = try self.allocator.dupe(u8, v);
    }
    pub fn setTextColor(self: *Widget, v: Color) !void {
        const c = self.textContent() orelse return error.WidgetHasNoText;
        c.color = v;
    }
    pub fn setFont(self: *Widget, v: Handle(Font)) !void {
         const c = self.textContent() orelse return error.WidgetHasNoText;
         c.font = v.ptr;
    }

    pub fn OnClick(self: *Widget, cb: Callback) !void {
        switch (self.data) {
            .button => |*b| b.on_click = cb,
            else => |d| { self.diagnostic.set("OnClick is only valid on buttons, got {s}", .{d.luaName()}); return error.NotClickable; },
        }
    }

    fn textContent(self: *Widget) ?*TextContent {
        return switch (self.data) { .label => |*l| &l.content, .button => |*b| &b.content, .panel => null };
    }

    pub fn update(self: *Widget, container_w: f32, container_h: f32, default_font: *Font) void {
        const f = self.anchor.factor();
        switch (self.data) {
            .label => |l| {
                const font = l.content.font orelse default_font;
                const sz = font.measure(l.content.text) catch TextSize{ .w = 0, .h = 0 };

                self.size = .{ @floatFromInt(sz.w), @floatFromInt(sz.h) };
            },

            else => {}
        }

        const size_w = self.size[0];
        const size_h = self.size[1];

        const origin_x = container_w * f[0] + self.offset[0] - size_w * f[0];
        const origin_y = container_h * f[1] + self.offset[1] - size_h * f[1];

        self.resolved = .{ .x = @trunc(origin_x), .y = @trunc(origin_y), .w = @trunc(size_w), .h = @trunc(size_h) };
    }

    pub fn deinit(self: *Widget) void {
        if (self.textContent()) |c| self.allocator.free(c.text);

        switch (self.data) {
            .button => |b| {
                if (b.on_click) |cb| {
                    cb.deinit();
                }
            },

            else => {}
        }
    }
};
