// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

pub const Vec4 = @Vector(4, f32);
pub const Vec3 = @Vector(3, f32);
pub const Vec2 = @Vector(2, f32);

pub const Mat4 = struct {
    rows: [4]Vec4,

    pub fn initZero() Mat4 {
        return .{ .rows = .{ @splat(0), @splat(0), @splat(0), @splat(0) } };
    }
};

pub const Transform = struct {
    position: Vec3,
    rotation: Vec3,

    pub fn onlyPosition(self: *Transform) Transform {
        var t = Transform.identity();
        t.position = self.position;

        return t;
    }

    pub fn zero() Transform {
        return .{
            .position = Vec3{ 0, 0, 0 },
            .rotation = Vec3{ 0, 0, 0 },
        };
    }

    pub fn identity() Transform {
        return .{
            .position = Vec3{ 0, 0, 0 },
            .rotation = Vec3{ 0, 0, 0 },
        };
    }
};

pub const ScaledTransform = struct {
    transform: Transform,
    scale: Vec3,

    pub fn identity() ScaledTransform {
        return .{ .transform = Transform.identity(), .scale = Vec3{ 1, 1, 1 } };
    }
};
