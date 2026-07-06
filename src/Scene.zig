// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");
const Vec3_SIMD = types.Vec3_SIMD;
const Vec2_SIMD = types.Vec2_SIMD;
const Vertex = types.Vertex;
const Face = types.Face;

const Object = @import("object.zig").Object;
const Camera = @import("Camera.zig").Camera;
const MeshData = @import("MeshData.zig").MeshData;
pub var skybox_mesh: ?MeshData = null;

pub const UpdateCallback = struct {
    ctx: ?*anyopaque,
    func: *const fn (ctx: ?*anyopaque, dt: f32) void,
};

pub const Scene = struct {
    allocator: std.mem.Allocator,
    objects: std.ArrayList(*Object),
    name: ?[]const u8,
    callbacks: std.ArrayList(UpdateCallback),
    camera: ?*Camera,
    skybox: MeshData,

    pub fn init(allocator: std.mem.Allocator, name: ?[]const u8, camera: ?*Camera) !Scene {
        return .{
            .name = name,
            .allocator = allocator,
            .objects = std.ArrayList(*Object).empty,
            .callbacks = std.ArrayList(UpdateCallback).empty,
            .camera = camera,
            .skybox = skybox_mesh orelse return error.SkyboxNotInitialized
        };
    }

    pub fn deinit(self: *Scene) void {
        self.objects.deinit(self.allocator);
        self.callbacks.deinit(self.allocator);
        self.skybox.deinit();
    }

    pub fn addObject(self: *Scene, object: *Object) !void {
        try self.objects.append(self.allocator, object);
    }

    pub fn removeObject(self: *Scene, object: *const Object) void {
        for (self.objects.items, 0..) |obj, i| {
            if (obj == object) {
                _ = self.objects.swapRemove(i);
                return;
            }
        }
    }

    pub fn addUpdateCallback(self: *Scene, cb: UpdateCallback) !void {
        try self.callbacks.append(self.allocator, cb);
    }

    pub fn removeUpdateCallback(self: *Scene, ctx: ?*anyopaque) void {
        for (self.callbacks.items, 0..) |cb, i| {
            if (cb.ctx == ctx) {
                _ = self.callbacks.swapRemove(i);
                return;
            }
        }
    }

    pub fn update(self: *Scene, dt: f32) void {
        for (self.callbacks.items) |cb| {
            cb.func(cb.ctx, dt);
        }
    }
};
