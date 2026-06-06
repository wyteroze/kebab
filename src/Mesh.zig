// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("types.zig");
const obj_parser = @import("parsers/obj.zig");

const Vec3_SIMD = types.Vec3_SIMD;
const Face = types.Face;

pub const Mesh = struct {
    allocator: std.mem.Allocator,
    vertices: []Vec3_SIMD,
    indices: []usize,
    faces: []types.Face,

    pub fn init(
        allocator: std.mem.Allocator,
        vertices: []const Vec3_SIMD,
        indices: []const usize,
        faces: []const Face
    ) !Mesh {
        const v = try allocator.dupe(Vec3_SIMD, vertices);
        errdefer allocator.free(v);

        const i = try allocator.dupe(usize, indices);
        errdefer allocator.free(i);

        const f = try allocator.dupe(Face, faces);
        errdefer allocator.free(f);

        return .{
            .allocator = allocator,
            .vertices = v,
            .indices = i,
            .faces = f
        };
    }

    pub fn loadFromFile(allocator: std.mem.Allocator, io: std.Io, path: []const u8) !Mesh {
        var file = try std.Io.Dir.cwd().openFile(io, path, .{});
        defer file.close(io);

        var buffer: [4096]u8 = undefined;

        var file_reader = file.reader(io, &buffer);
        const reader = &file_reader.interface;

        const mesh = try obj_parser.parseObj(allocator, reader);
        return mesh;
    }

    pub fn deinit(self: Mesh) void {
        self.allocator.free(self.vertices);
        self.allocator.free(self.indices);
        self.allocator.free(self.faces);
    }
};
