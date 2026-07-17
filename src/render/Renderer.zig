// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");

const perf = @import("../profile/perf.zig");
const engine_types = @import("../types.zig");
const Scene = @import("../Scene.zig").Scene;
const RenderTarget = @import("RenderTarget.zig").RenderTarget;
const Pipeline3D = @import("Pipeline3D.zig").Pipeline3D;
const Rasterizer = @import("Rasterizer.zig");
const Transform = engine_types.Transform;

pub const Renderer = struct {
    pipeline: Pipeline3D,

    pub fn init(allocator: std.mem.Allocator) !Renderer {
        return .{ .pipeline = try Pipeline3D.init(allocator) };
    }

    pub fn deinit(self: *Renderer) void {
        self.pipeline.deinit();
    }

    pub fn renderScene(self: *Renderer, target: *RenderTarget, scene: *Scene) !void {
        self.pipeline.beginFrame();
        const size_x = target.size_x;
        const size_y = target.size_y;

        perf.start("geometry"); {
            if (scene.skybox.texture != null) {
                const cam = if (scene.camera) |obj| obj.data.camera.camera else null;
                const skybox_pos = if (cam) |c| &c.transform.onlyPosition() else &Transform.identity();
                try self.pipeline.submitMesh(size_x, size_y, &scene.skybox, scene.skybox.texture, skybox_pos, cam);
            }

            for (scene.objects.items) |obj| {
                switch (obj.data) {
                    .mesh => |m| {
                        const cam = if (scene.camera) |o| o.data.camera.camera else null;
                        try self.pipeline.submitMesh(size_x, size_y, m.mesh, m.texture, obj.data.transform(), cam);
                    },

                    else => {}
                }
            }
        } perf.stop();

        perf.start("raster"); {
            Rasterizer.flush(target, self.pipeline.tris.items, self.pipeline.commands.items);
        } perf.stop();
    }
};
