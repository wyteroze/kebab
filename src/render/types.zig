// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const types = @import("../types.zig");
const ImageData = @import("../ImageData.zig").ImageData;

pub const DrawCommand = struct { first: usize, count: usize, texture: ?*const ImageData };
pub const Rect = struct { x: i32, y: i32, w: i32, h: i32 };

pub const Plane = struct { point: types.Vec3, normal: types.Vec3 };
pub const Face = struct {
    start: usize, // index into indices
    length: usize
};

pub const Vertex = struct {
    position: types.Vec3,
    uv: types.Vec2
};

pub const Triangle = struct {
    pa: Vertex,
    pb: Vertex,
    pc: Vertex,
    color: u32, // 0x_AA_RR_GG_BB
    depth: f32
};
