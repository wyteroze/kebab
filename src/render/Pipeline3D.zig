// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const math = @import("../math.zig");
const engine_types = @import("../types.zig");
const types = @import("types.zig");
const MeshData = @import("../MeshData.zig").MeshData;
const ImageData = @import("../ImageData.zig").ImageData;
const Camera = @import("../Camera.zig").Camera;

const Vec2 = engine_types.Vec2;
const Vec3 = engine_types.Vec3;
const Vec4 = engine_types.Vec4;
const Mat4 = engine_types.Mat4;
const Transform = engine_types.Transform;
const Triangle = types.Triangle;
const Vertex = types.Vertex;
const Plane = types.Plane;
const DrawCommand = types.DrawCommand;

pub const Pipeline3D = struct {
    allocator: std.mem.Allocator,
    default_camera: *Camera,
    tris: std.ArrayList(Triangle),
    commands: std.ArrayList(DrawCommand),
    clip_scratch: std.ArrayList(Triangle),

    pub fn init(allocator: std.mem.Allocator) !Pipeline3D {
        const default_transform = try allocator.create(Transform);
        default_transform.* = Transform.identity();

        const default_camera = try allocator.create(Camera);
        default_camera.* = Camera.init(0.1, 1000.0, 90.0, undefined);
        default_camera.transform = default_transform;

        return .{
            .allocator = allocator,
            .default_camera = default_camera,
            .tris = .empty,
            .commands = .empty,
            .clip_scratch = .empty,
        };
    }

    pub fn deinit(self: *Pipeline3D) void {
        self.allocator.destroy(self.default_camera.transform);
        self.allocator.destroy(self.default_camera);
        self.tris.deinit(self.allocator);
        self.commands.deinit(self.allocator);
        self.clip_scratch.deinit(self.allocator);
    }

    pub fn beginFrame(self: *Pipeline3D) void {
        self.tris.clearRetainingCapacity();
        self.commands.clearRetainingCapacity();
    }

    pub fn submitMesh(
        self: *Pipeline3D,
        size_x: usize, size_y: usize,
        mesh_data: *const MeshData,
        texture: ?*const ImageData,
        transform: *const Transform,
        cam: ?*Camera,
    ) !void {
        const first = self.tris.items.len;

        const aspect_ratio = @as(f32, @floatFromInt(size_y)) / @as(f32, @floatFromInt(size_x));
        const camera = cam orelse self.default_camera;
        const camera_transform = camera.transform;
        const projection_matrix = camera.getProjectionMatrix(aspect_ratio);
        const view_matrix = camera.getViewMatrix();

        const rotationRad = transform.rotation * @as(Vec3, @splat(std.math.pi / 180.0));
        const rotate_x_matrix = Mat4{ .rows = .{
            Vec4{ 1, 0, 0, 0 },
            Vec4{ 0, @cos(rotationRad[0]), @sin(rotationRad[0]), 0 },
            Vec4{ 0, -@sin(rotationRad[0]), @cos(rotationRad[0]), 0 },
            Vec4{ 0, 0, 0, 1 },
        }};
        const rotate_y_matrix = Mat4{ .rows = .{
            Vec4{ @cos(rotationRad[1]), 0, @sin(rotationRad[1]), 0 },
            Vec4{ 0, 1, 0, 0 },
            Vec4{ -@sin(rotationRad[1]), 0, @cos(rotationRad[1]), 0 },
            Vec4{ 0, 0, 0, 1 },
        }};
        const rotate_z_matrix = Mat4{ .rows = .{
            Vec4{ @cos(rotationRad[2]), @sin(rotationRad[2]), 0, 0 },
            Vec4{ -@sin(rotationRad[2]), @cos(rotationRad[2]), 0, 0 },
            Vec4{ 0, 0, 1, 0 },
            Vec4{ 0, 0, 0, 1 },
        }};

        var world_matrix = math.multiplyMatrices(
            math.multiplyMatrices(rotate_z_matrix, rotate_y_matrix),
            rotate_x_matrix,
        );
        world_matrix.rows[3] += Vec4{ transform.position[0], transform.position[1], transform.position[2], 0.0 };

        const f_width = @as(f32, @floatFromInt(size_x));
        const f_height = @as(f32, @floatFromInt(size_y));
        const planes = [4]Plane{
            .{ .point = .{ 0.0, 0.0, 0.0 },      .normal = .{ 0.0, 1.0, 0.0 } },  // top
            .{ .point = .{ 0.0, f_height, 0.0 }, .normal = .{ 0.0, -1.0, 0.0 } }, // bottom
            .{ .point = .{ 0.0, 0.0, 0.0 },      .normal = .{ 1.0, 0.0, 0.0 } },  // left
            .{ .point = .{ f_width, 0.0, 0.0 },  .normal = .{ -1.0, 0.0, 0.0 } }, // right
        };

        for (mesh_data.faces) |*face| {
            var i: usize = 0;
            while (i < face.length) : (i += 3) {
                const ia = mesh_data.vertices[mesh_data.indices[face.start + i]];
                const ib = mesh_data.vertices[mesh_data.indices[face.start + i + 1]];
                const ic = mesh_data.vertices[mesh_data.indices[face.start + i + 2]];

                const va = math.multiplyMatrixVector(world_matrix, ia.position);
                const vb = math.multiplyMatrixVector(world_matrix, ib.position);
                const vc = math.multiplyMatrixVector(world_matrix, ic.position);

                // culling
                const world_normal = math.normal(va, vb, vc);
                const view_dir = math.normalize(va - camera_transform.position);
                if (math.dot(world_normal, view_dir) >= 0.0) continue;

                // lighting
                const light_direction = math.normalize(Vec3{ 0.0, 0.0, -1.0 });
                const light_normal = math.dot(light_direction, world_normal);
                const color = math.luminanceToRGB(light_normal);

                // world -> view
                var view_space = Triangle{
                    .pa = Vertex{ .position = math.multiplyMatrixVector(view_matrix, va), .uv = ia.uv },
                    .pb = Vertex{ .position = math.multiplyMatrixVector(view_matrix, vb), .uv = ib.uv },
                    .pc = Vertex{ .position = math.multiplyMatrixVector(view_matrix, vc), .uv = ic.uv },
                    .color = color,
                    .depth = 0,
                };
                view_space.depth = (view_space.pa.position[2] + view_space.pb.position[2] + view_space.pc.position[2]) / 3.0;

                const clip = math.clipTriangleAgainstPlane(Vec3{ 0.0, 0.0, 0.1 }, Vec3{ 0.0, 0.0, 1.0 }, view_space);

                for (0..clip.n) |n| {
                    const clipped = switch (n) {
                        0 => clip.t1.?,
                        1 => clip.t2.?,
                        else => unreachable,
                    };

                    const proj_a = math.multiplyMatrixVectorW(projection_matrix, clipped.pa.position);
                    const proj_b = math.multiplyMatrixVectorW(projection_matrix, clipped.pb.position);
                    const proj_c = math.multiplyMatrixVectorW(projection_matrix, clipped.pc.position);

                    const uv_a = clipped.pa.uv / @as(Vec2, @splat(proj_a.w));
                    const uv_b = clipped.pb.uv / @as(Vec2, @splat(proj_b.w));
                    const uv_c = clipped.pc.uv / @as(Vec2, @splat(proj_c.w));

                    var p = [3]Vec3{
                        proj_a.xyz / @as(Vec3, @splat(proj_a.w)),
                        proj_b.xyz / @as(Vec3, @splat(proj_b.w)),
                        proj_c.xyz / @as(Vec3, @splat(proj_c.w)),
                    };

                    const sx = 0.5 * f_width;
                    const sy = 0.5 * f_height;
                    inline for (&p) |*v| {
                        v[0] = (v[0] + 1.0) * sx;
                        v[1] = (1.0 - v[1]) * sy; // invert y
                    }

                    const screen_tri = Triangle{
                        .pa = Vertex{ .position = Vec3{ p[0][0], p[0][1], 1.0 / proj_a.w }, .uv = uv_a },
                        .pb = Vertex{ .position = Vec3{ p[1][0], p[1][1], 1.0 / proj_b.w }, .uv = uv_b },
                        .pc = Vertex{ .position = Vec3{ p[2][0], p[2][1], 1.0 / proj_c.w }, .uv = uv_c },
                        .color = clipped.color,
                        .depth = clipped.depth,
                    };

                    try self.screenClipAndAppend(screen_tri, planes);
                }
            }
        }

        try self.commands.append(self.allocator, .{
            .first = first,
            .count = self.tris.items.len - first,
            .texture = texture,
        });
    }

    fn screenClipAndAppend(self: *Pipeline3D, tri: Triangle, planes: [4]Plane) !void {
        self.clip_scratch.clearRetainingCapacity();
        try self.clip_scratch.append(self.allocator, tri);

        for (0..4) |pl| {
            const n = self.clip_scratch.items.len;

            for (0..n) |k| {
                const test_tri = self.clip_scratch.items[k];
                const clip = math.clipTriangleAgainstPlane(planes[pl].point, planes[pl].normal, test_tri);

                for (0..clip.n) |w| {
                    const clipped = if (w == 0) clip.t1.? else clip.t2.?;
                    try self.clip_scratch.append(self.allocator, clipped);
                }
            }

            self.clip_scratch.replaceRangeAssumeCapacity(0, n, &.{});
        }

        try self.tris.appendSlice(self.allocator, self.clip_scratch.items);
    }
};
