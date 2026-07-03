// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const zlua = @import("zlua");
const types = @import("../../types.zig");
const shared = @import("../shared.zig");
const strEq = shared.strEq;
const Lua = zlua.Lua;
const object = @import("../../object.zig");

const Mesh = @import("../../Mesh.zig").Mesh;
const Sprite = @import("../../Sprite.zig").Sprite;

pub fn index(_: *Lua, _: *object.MeshObject, _: []const u8) ?i32 { return null; }

pub fn newIndex(_: *Lua, _: *object.MeshObject, _: []const u8) ?void { return null; }

pub fn gc(m: *object.MeshObject, allocator: std.mem.Allocator) void {
    m.mesh.deinit();
    m.texture.?.deinit(allocator);
}

pub fn construct(l: *Lua, obj: *object.Object, _: std.mem.Allocator) i32 {
    const mesh_data = l.checkUserdata(Mesh, 1, "MeshData");
    const texture = if (l.isNoneOrNil(2)) null else l.checkUserdata(Sprite, 2, "ImageData");
    obj.* = .{
        .transform = types.Transform.identity(),
        .data = .{ .mesh = .{ .mesh = mesh_data, .texture = texture } }
    };

    return 1;
}
