// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const types = @import("../types.zig");
const Mesh = @import("../Mesh.zig").Mesh;

const Vec3_SIMD = types.Vec3_SIMD;
const Face = types.Face;

pub const ParseError = error{
    MissingComponents,
    InvalidFaceData,
    InvalidFloat,
    InvalidInt
};

pub fn parseObj(allocator: std.mem.Allocator, reader: *std.Io.Reader) !Mesh {
    var vertices = std.ArrayList(Vec3_SIMD).empty;
    defer vertices.deinit(allocator);
    var indices = std.ArrayList(usize).empty;
    defer indices.deinit(allocator);
    var faces = std.ArrayList(Face).empty;
    defer faces.deinit(allocator);

    while (try reader.takeDelimiter('\n')) |line| {
        if (std.mem.startsWith(u8, line, "#")) {
            continue; // comment
        } else if (std.mem.startsWith(u8, line, "vn")) {
            continue; // we don't care about normals
        } else if (std.mem.startsWith(u8, line, "vt")) {
            continue; // we don't care about uv mapping
        } else if (std.mem.startsWith(u8, line, "v ")) {
            const vertex = try parseVertexLine(line);
            try vertices.append(allocator, vertex);
        } else if (std.mem.startsWith(u8, line, "f ")) {
            const start_idx = indices.items.len;
            try parseFaceLine(allocator, line, &indices);

            try faces.append(allocator, .{
                .start = start_idx,
                .length = 3
            });
        }
    }

    return Mesh.init(
        allocator,
        vertices.items,
        indices.items,
        faces.items
    );
}

fn parseVertexLine(line: []const u8) ParseError!Vec3_SIMD {
    var iter = std.mem.splitScalar(u8, line, ' ');
    _ = iter.next(); // consume "v"

    var vertex: [3]f32 = undefined;
    var index: usize = 0;
    while (iter.next()) |component| {
        if (component.len == 0) continue;
        if (index >= 3) break;

        vertex[index] = std.fmt.parseFloat(f32, component)
            catch return ParseError.InvalidFloat;

        index += 1;
    }

    if (index < 3) return ParseError.MissingComponents;
    return Vec3_SIMD{ vertex[0], vertex[1], vertex[2] };
}

fn parseFaceLine(allocator: std.mem.Allocator, line: []const u8, indices: *std.ArrayList(usize)) !void {
    var space_iter = std.mem.splitScalar(u8, line, ' ');
    _ = space_iter.next(); // consume "f"

    var corner_count: usize = 0;
    while (space_iter.next()) |corner_str| {
        if (corner_str.len == 0) continue;
        if (corner_count >= 3) break;

        var slash_iter = std.mem.splitScalar(u8, corner_str, '/');
        const v_str = slash_iter.next()
            orelse return ParseError.InvalidFaceData;

        const obj_idx = std.fmt.parseInt(usize, v_str, 10)
            catch return ParseError.InvalidInt;

        if (obj_idx == 0) return ParseError.InvalidFaceData;

        indices.append(allocator, obj_idx-1)
            catch return error.OutOfMemory;

        corner_count += 1;
    }

    if (corner_count < 3) return ParseError.InvalidFaceData;
}
