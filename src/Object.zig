// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");

const MeshData = @import("MeshData.zig").MeshData;
const ImageData = @import("ImageData.zig").ImageData;
const Camera = @import("Camera.zig").Camera;
pub const ObjectKind = enum { mesh_data, image, camera };

pub const Object = struct {
    transform: types.Transform,
    data: union(ObjectKind) {
        mesh_data: MeshObject,
        image: ImageObject,
        camera: CameraObject,

        pub fn luaName(self: @This()) []const u8 {
            return switch (self) {
                .mesh_data => "MeshData",
                .image => "Image",
                .camera => "Camera"
            };
        }
    }
};

pub const MeshObject = struct {
    mesh_data: *const MeshData,
    texture: ?*const ImageData,
    mesh_ref: i32,
    texture_ref: ?i32 = null
};

pub const ImageObject = struct {
    image: *const ImageData,
    image_ref: i32,
};

pub const CameraObject = struct {
    camera: *Camera
};
