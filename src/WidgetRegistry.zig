// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const Widget = @import("ui/Widget.zig").Widget;

pub const WidgetRegistry = struct {
    allocator: std.mem.Allocator,
    widgets: std.ArrayList(*Widget),

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
};
