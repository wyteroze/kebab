// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const Widget = @import("../../ui/Widget.zig").Widget;
const Anchor = @import("../../ui/Widget.zig").Anchor;
const Font = @import("../../ui/Font.zig").Font;
const Color = @import("../../Color.zig").Color;
const Diagnostic = @import("../shared.zig").Diagnostic;
const WidgetRegistry = @import("../../WidgetRegistry.zig").WidgetRegistry;
const Vec2 = @import("../objects/Vec2.zig").Vec2;
const Handle = @import("../reflect/marshal.zig").Handle;

const white = Color{ .color = 0xFFFFFFFF };
const button_bg = Color{ .color = 0xFF3B3B3B };

pub const UILib = struct {
    pub const name = "UI";
    pub const hidden = .{ "registry" };
    registry: *WidgetRegistry,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, registry: *WidgetRegistry) UILib {
        return .{
            .allocator = allocator,
            .registry = registry
        };
    }

    pub fn Panel(self: *UILib, anchor: Anchor, offset: Vec2, size: Vec2) !Handle(Widget) {
        const widget = try self.allocator.create(Widget);
        errdefer self.allocator.destroy(widget);

        widget.* = .{
            .allocator = self.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = size.vec,
            .data = .{ .panel = .{ .bg = white } },
        };

        try self.registry.addWidget(widget);
        return .{ .ptr = widget };
    }

    pub fn Label(self: *UILib, anchor: Anchor, offset: Vec2, text: []const u8) !Handle(Widget) {
        const owned = try self.allocator.dupe(u8, text);
        errdefer self.allocator.free(owned);

        const widget = try self.allocator.create(Widget);
        errdefer self.allocator.destroy(widget);

        widget.* = .{
            .allocator = self.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = .{ 0, 0 }, // updated at draw time to reflect the size of the text
            .data = .{ .label = .{ .content = .{ .text = owned, .color = white } } },
        };

        try self.registry.addWidget(widget);
        return .{ .ptr = widget };
    }

    pub fn Button(self: *UILib, anchor: Anchor, offset: Vec2, size: Vec2, text: []const u8) !Handle(Widget) {
        const owned = try self.allocator.dupe(u8, text);
        errdefer self.allocator.free(owned);

        const widget = try self.allocator.create(Widget);
        errdefer self.allocator.destroy(widget);

        widget.* = .{
            .allocator = self.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = size.vec,
            .data = .{ .button = .{ .bg = button_bg, .content = .{ .text = owned, .color = white } } },
        };

        try self.registry.addWidget(widget);
        return .{ .ptr = widget };
    }
};
