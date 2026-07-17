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
const Font = @import("../ui/Font.zig").Font;
const UIPainter = @import("UIPainter.zig");
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

    pub fn drawWidgets(_: *Renderer, target: *RenderTarget, default_font: *Font, widgets: []*Widget) !void {
        const cw = @as(f32, @floatFromInt(target.size_x));
        const ch = @as(f32, @floatFromInt(target.size_y));

        perf.start("draw UI"); {
            for (widgets) |w| {
                if (!w.visible) continue;
                w.update(cw, ch, default_font);

                const r = w.resolved;
                const x = @as(i32, @intFromFloat(r.x));
                const y = @as(i32, @intFromFloat(r.y));
                const rw = @as(i32, @intFromFloat(r.w));
                const rh = @as(i32, @intFromFloat(r.h));

                switch (w.data) {
                    .panel => |p| UIPainter.rect(target, x, y, rw, rh, p.bg.color, null),
                    .label => |l| {
                        const font = l.content.font orelse default_font;
                        UIPainter.text(target, font, x, y, l.content.text, l.content.color.color, null);
                    },
                    .button => |b| {
                        UIPainter.rect(target, x, y, rw, rh, b.bg.color, null);
                        const font = b.content.font orelse default_font;
                        UIPainter.text(target, font, x, y, b.content.text, b.content.color.color, null);
                    },
                }
            }
        } perf.stop();
    }
};
