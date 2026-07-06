// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const MeshData = @import("../../MeshData.zig").MeshData;
const ImageData = @import("../../ImageData.zig").ImageData;

const mesh_path = "src/assets/models/";
const image_path = "src/assets/images/";

pub const Assets = struct {
    allocator: std.mem.Allocator,
    io: std.Io,

    pub fn init(allocator: std.mem.Allocator, io: std.Io) Assets {
        return .{
            .allocator = allocator,
            .io = io
        };
    }

    pub fn loadMesh(self: *Assets, path: []const u8) !MeshData {
        const full_path = try std.mem.concat(self.allocator, u8, &.{ mesh_path, path });
        defer self.allocator.free(full_path);

        return try MeshData.loadFromFile(self.allocator, self.io, full_path);
    }

    pub fn loadImage(self: *Assets, path: []const u8) !ImageData {
        const full_path = try std.mem.concat(self.allocator, u8, &.{ image_path, path });
        defer self.allocator.free(full_path);

        return try ImageData.loadFromFile(self.allocator, self.io, full_path);
    }
};
