// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");

const perf = @import("../profile/perf.zig");
const engine_types = @import("../types.zig");
const Scene = @import("../Scene.zig").Scene;
const RenderTarget = @import("RenderTarget.zig").RenderTarget;
const Pipeline3D = @import("Pipeline3D.zig").Pipeline3D;
const Rasterizer = @import("Rasterizer.zig");
const Transform = engine_types.Transform;
const Widget = @import("../ui/Widget.zig").Widget;
const AbsRect = @import("../ui/Widget.zig").AbsRect;
const Font = @import("../ui/Font.zig").Font;
const UIPainter = @import("UIPainter.zig");
const Painter = @import("Painter.zig").Painter;
const Rect = @import("types.zig").Rect;
const Camera = @import("../Camera.zig").Camera;

pub const Renderer = struct {
    pipeline: Pipeline3D,

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        return .{ .pipeline = try Pipeline3D.init(allocator) };
    }

    pub fn deinit(self: *Renderer) void {
        self.pipeline.deinit();
    }

    pub fn renderScene(self: *Renderer, target: *RenderTarget, scene: *Scene, camera: ?*Camera) !void {
        self.pipeline.beginFrame();
        const size_x = target.size_x;
        const size_y = target.size_y;

        perf.start("geometry"); {
            if (scene.skybox.texture != null) {
                const skybox_pos = if (camera) |c| &c.transform.onlyPosition() else &Transform.identity();
                try self.pipeline.submitMesh(size_x, size_y, &scene.skybox, scene.skybox.texture, skybox_pos, camera);
            }

            for (scene.objects.items) |obj| {
                switch (obj.data) {
                    .mesh => |m| {
                        try self.pipeline.submitMesh(size_x, size_y, m.mesh, m.texture, obj.data.transform(), camera);
                    },

                    else => {}
                }
            }
        } perf.stop();

        perf.start("raster"); {
            Rasterizer.flush(target, self.pipeline.tris.items, self.pipeline.commands.items);
        } perf.stop();
    }

    pub fn drawWidgets(_: *Renderer, target: *RenderTarget, default_font: *Font, roots: []*Widget) !void {
        const window_rect = AbsRect{
            .x = 0, .y = 0,
            .w = @floatFromInt(target.size_x),
            .h = @floatFromInt(target.size_y),
        };

        perf.start("draw UI"); {
            for (roots) |root| {
                perf.start("ui layout"); { root.layoutTree(window_rect, default_font); } perf.stop();
                perf.start("ui paint"); { paintTree(target, default_font, root, null); } perf.stop();
            }
        } perf.stop();
    }

    fn paintTree(target: *RenderTarget, font: *Font, w: *Widget, clip: ?Rect) void {
        if (!w.visible) return;

        const own_clip = intersect(clip, rectOf(w.resolved));
        if (own_clip.w <= 0 or own_clip.h <= 0) return;

        var painter = Painter{
            .target = target,
            .origin = .{ w.resolved.x, w.resolved.y },
            .clip = own_clip,
            .font = font,
        };
        w.paint(&painter);

        const child_clip = if (w.clipsChildren()) own_clip else clip;
        for (w.childSlice()) |c| paintTree(target, font, c, child_clip);
    }

    fn rectOf(r: AbsRect) Rect {
        return .{
            .x = @intFromFloat(r.x), .y = @intFromFloat(r.y),
            .w = @intFromFloat(r.w), .h = @intFromFloat(r.h),
        };
    }

    fn intersect(a: ?Rect, b: Rect) Rect {
        const lhs = a orelse return b;
        const x0 = @max(lhs.x, b.x);
        const y0 = @max(lhs.y, b.y);
        const x1 = @min(lhs.x + lhs.w, b.x + b.w);
        const y1 = @min(lhs.y + lhs.h, b.y + b.h);

        return .{ .x = x0, .y = y0, .w = @max(0, x1 - x0), .h = @max(0, y1 - y0) };
    }
};
