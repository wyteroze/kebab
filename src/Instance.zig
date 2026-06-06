// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");

const Mesh = @import("Mesh.zig").Mesh;

pub const Instance = struct {
    mesh: *const Mesh,
    transform: types.Transform
};
