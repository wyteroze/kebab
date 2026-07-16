// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const Vec2 = @import("../objects/Vec2.zig").Vec2;

pub const Vec2Lib = struct {
    pub const name = "Vec2";

    pub fn init() Vec2Lib { return .{}; }

    pub fn new(x: f32, y: f32) Vec2 {
        return Vec2.init(x, y);
    }
};
