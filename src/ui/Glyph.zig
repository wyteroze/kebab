// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");

// We use u32 because it's the max size of .bmp files.

pub const Glyph = struct {
    pos_x: u32, pos_y: u32,
    size_x: u32, size_y: u32,

    advance: u32,
};
