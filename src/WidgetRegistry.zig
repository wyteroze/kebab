// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const ButtonData = @import("ui/Widget.zig").ButtonData;
const Widget = @import("ui/Widget.zig").Widget;

pub const WidgetRegistry = struct {
    allocator: std.mem.Allocator,
    widgets: std.ArrayList(*Widget),
    hovered: ?*Widget = null,
    pressed: ?*Widget = null,

    pub fn init(allocator: std.mem.Allocator) WidgetRegistry {
        return .{
            .allocator = allocator,
            .widgets = .empty
        };
    }

    pub fn deinit(self: *WidgetRegistry) void {
        for (self.widgets.items) |w| {
            w.deinit();
            self.allocator.destroy(w);
        }

        self.widgets.deinit(self.allocator);
    }

    pub fn addWidget(self: *WidgetRegistry, widget: *Widget) !void {
        try self.widgets.append(self.allocator, widget);
    }

    pub fn removeWidget(self: *WidgetRegistry, widget: *Widget) void {
        for (self.widgets.items, 0..) |w, i| {
            if (w == widget) {
                w.deinit();
                _ = self.widgets.swapRemove(i);
                self.allocator.destroy(w);
                return;
            }
        }
    }

    fn hitTest(self: *WidgetRegistry, cx: f32, cy: f32) ?*Widget {
        var i = self.widgets.items.len;
        while (i > 0) {
            i -= 1;
            const w = self.widgets.items[i];
            if (!w.visible) continue;
            const r = w.resolved;
            if (cx >= r.x and cx < r.x + r.w and cy >= r.y and cy < r.y + r.h) return w;
        }

        return null;
    }

    fn asButton(w: *Widget) ?*ButtonData {
        return switch (w.data) { .button => |*b| b, else => null };
    }

    pub fn handlePointerEvent(self: *WidgetRegistry, event: sdl3.events.Event, scale: f32) bool {
        switch (event) {
            .mouse_motion => |m| {
                const hit = self.hitTest(m.x / scale, m.y / scale);

                if (self.hovered) |h| if (h != hit) if (asButton(h)) |b| { b.state = .normal; };
                self.hovered = hit;

                if (hit) |w| if (asButton(w)) |b| { b.state = if (w == self.pressed) .pressed else .hover; };

                return hit != null or self.pressed != null;
            },
            .mouse_button_down => |m| {
                if (m.button != .left) return false;

                const hit = self.hitTest(m.x / scale, m.y / scale);
                if (hit) |w| if (asButton(w)) |b| { self.pressed = w; b.state = .pressed; };

                return hit != null;
            },
            .mouse_button_up => |m| {
                if (m.button != .left) return false;

                const had_press = self.pressed != null;
                const hit = self.hitTest(m.x / scale, m.y / scale);
                if (self.pressed) |w| {
                    if (hit == w) if (asButton(w)) |b| if (b.on_click) |cb| cb.call(.{});
                    if (asButton(w)) |b| { b.state = if (hit == w) .hover else .normal; }
                }

                self.pressed = null;
                return had_press;
            },

            else => return false,
        }
    }
};
