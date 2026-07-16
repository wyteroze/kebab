// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");

// We use u32 because it's the max size of .bmp files.
const Vec2_u32 = @import("../types.zig").Vec2_u32;

pub const Glyph = struct {
    pos: Vec2_u32,
    size: Vec2_u32,
    advance: u32,
};
