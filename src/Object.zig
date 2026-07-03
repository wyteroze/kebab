// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");

const Mesh = @import("Mesh.zig").Mesh;
const Sprite = @import("Sprite.zig").Sprite;
const Camera = @import("Camera.zig").Camera;
pub const ObjectKind = enum { mesh, image, camera };

pub const Object = struct {
    transform: types.Transform,
    data: union(ObjectKind) {
        mesh: MeshObject,
        image: ImageObject,
        camera: CameraObject
    }
};

pub const MeshObject = struct {
    mesh: *const Mesh,
    texture: ?*const Sprite
};

pub const ImageObject = struct {
    image: *const Sprite
};

pub const CameraObject = struct {
    camera: *Camera
};
