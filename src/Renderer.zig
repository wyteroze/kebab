// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl = @import("zsdl2");

const math      = @import("math.zig");
const types     = @import("types.zig");
const Mesh      = @import("Mesh.zig").Mesh;
const Camera    = @import("Camera.zig").Camera;

const Mat4 = types.Mat4;
const Triangle  = types.Triangle;
const Transform = types.Transform;
const Vec3_SIMD = types.Vec3_SIMD;
const Vec4_SIMD = types.Vec4_SIMD;
pub const Vec2_cint = struct { x: c_int, y: c_int };
pub const Plane = struct { point: Vec3_SIMD, normal: Vec3_SIMD };

const clear_color = 0xFF_8A_AA_FF;

pub const Renderer = struct {
    allocator: std.mem.Allocator,
    renderer: *sdl.Renderer,
    texture: *sdl.Texture,
    framebuffer: []u32,
    size: Vec2_cint,
    camera: *Camera,
    tri_buffer: std.ArrayList(Triangle),
    tri_raster_list: std.ArrayList(Triangle),

    pub fn init(allocator: std.mem.Allocator, window: *sdl.Window, size: Vec2_cint, camera: *Camera, vsync: ?bool) !Renderer {
        const renderer = try sdl.createRenderer(window, null, .{ .accelerated = true, .present_vsync = vsync orelse false });
        const texture = try sdl.createTexture(renderer, .argb8888, .streaming, size.x, size.y);

        return .{
            .allocator = allocator,
            .renderer = renderer,
            .texture = texture,
            .framebuffer = try allocator.alloc(u32, @as(usize, @intCast(size.x * size.y))),
            .size = size,
            .camera = camera,
            .tri_buffer = std.ArrayList(Triangle).empty,
            .tri_raster_list = std.ArrayList(Triangle).empty
        };
    }

    pub fn deinit(self: *Renderer) void {
        self.renderer.destroy();
        self.texture.destroy();
        self.allocator.free(self.framebuffer);
        self.tri_buffer.deinit(self.allocator);
        self.tri_raster_list.deinit(self.allocator);
    }

    pub fn present(self: Renderer) !void {
        try sdl.updateTexture(self.texture, null, self.framebuffer.ptr, self.size.x * @sizeOf(u32));
        try self.renderer.copy(self.texture, null, null);

        // renderer is sdl renderer, not this
        self.renderer.present();
    }


    // rendering methods
    pub fn drawBackground(self: *Renderer) void {
        @memset(self.framebuffer, clear_color);
    }

    pub fn drawMesh(self: *Renderer, mesh: *const Mesh, transform: *const Transform) !void {
        const camera_transform = self.camera.transform;
        const projection_matrix = self.camera.getProjectionMatrix();
        const view_matrix = self.camera.getViewMatrix();

        const rotationRad = transform.rotation * @as(Vec3_SIMD, @splat(std.math.pi / 180.0));
        const rotate_x_matrix = Mat4{ .rows = .{
            Vec4_SIMD{ 1, 0, 0, 0 },
            Vec4_SIMD{ 0, @cos(rotationRad[0]), @sin(rotationRad[0]), 0 },
            Vec4_SIMD{ 0, -@sin(rotationRad[0]), @cos(rotationRad[0]), 0 },
            Vec4_SIMD{ 0, 0, 0, 1 },
        }};

        const rotate_y_matrix = Mat4{ .rows = .{
            Vec4_SIMD{ @cos(rotationRad[1]), 0, @sin(rotationRad[1]), 0 },
            Vec4_SIMD{ 0, 1, 0, 0 },
            Vec4_SIMD{ -@sin(rotationRad[1]), 0, @cos(rotationRad[1]), 0 },
            Vec4_SIMD{ 0, 0, 0, 1 }
        }};

        const rotate_z_matrix = Mat4{ .rows = .{
            Vec4_SIMD{ @cos(rotationRad[2]), @sin(rotationRad[2]), 0, 0 },
            Vec4_SIMD{ -@sin(rotationRad[2]), @cos(rotationRad[2]), 0, 0 },
            Vec4_SIMD{ 0, 0, 1, 0 },
            Vec4_SIMD{ 0, 0, 0, 1 }
        }};

        // ZYX order rotation
        var world_matrix = math.multiplyMatrices(
            math.multiplyMatrices(rotate_z_matrix, rotate_y_matrix),
            rotate_x_matrix
        );

        // transform
        world_matrix.rows[3] += Vec4_SIMD{
            transform.position[0],
            transform.position[1],
            transform.position[2],
            0.0
        };

        self.tri_buffer.clearRetainingCapacity();
        for (mesh.faces) |*face| {
            var i = @as(usize, 0);

            while (i < face.length) : (i += 3) {
                const ia = mesh.indices[face.start + i];
                const ib = mesh.indices[face.start + i + 1];
                const ic = mesh.indices[face.start + i + 2];

                const va = math.multiplyMatrixVector(world_matrix, mesh.vertices[ia]);
                const vb = math.multiplyMatrixVector(world_matrix, mesh.vertices[ib]);
                const vc = math.multiplyMatrixVector(world_matrix, mesh.vertices[ic]);

                // culling
                const world_normal = math.normal(va, vb, vc);
                const view_dir = math.normalize(va - camera_transform.position);
                if (math.dot(world_normal, view_dir) >= 0.0) continue;

                // lighting
                const light_direction = math.normalize(Vec3_SIMD{ 0.0, 0.0, -1.0 });
                const light_normal = math.dot(light_direction, world_normal);
                const color = math.luminanceToRGB(light_normal);

                // world space to view space
                const view_space = [3]Vec3_SIMD{
                    math.multiplyMatrixVector(view_matrix, va),
                    math.multiplyMatrixVector(view_matrix, vb),
                    math.multiplyMatrixVector(view_matrix, vc)
                };

                const depth = (view_space[0][2] + view_space[1][2] + view_space[2][2]) / 3.0;

                const clip = math.clipTriangleAgainstPlane(Vec3_SIMD{ 0.0, 0.0, 0.1 }, Vec3_SIMD{ 0.0, 0.0, 1.0 }, .{
                    .color = color,
                    .depth = depth,
                    .pa = view_space[0],
                    .pb = view_space[1],
                    .pc = view_space[2]
                });

                for (0..clip.n) |n| {
                    const clipped = switch (n) {
                        0 => clip.t1.?,
                        1 => clip.t2.?,

                        else => unreachable
                    };

                    // project from 3d to 2d
                    var p = [3]Vec3_SIMD{
                        math.multiplyMatrixVector(projection_matrix, clipped.pa),
                        math.multiplyMatrixVector(projection_matrix, clipped.pb),
                        math.multiplyMatrixVector(projection_matrix, clipped.pc)
                    };

                    // scale into view
                    const sx = 0.5 * @as(f32, @floatFromInt(self.size.x));
                    const sy = 0.5 * @as(f32, @floatFromInt(self.size.y));

                    inline for (&p) |*v| {
                        v[0] = (v[0] + 1.0) * sx;
                        v[1] = (1.0 - v[1]) * sy; // invert y
                    }

                    // add to buffer to be rendered later
                    try self.tri_buffer.append(self.allocator, .{
                        .pa = p[0],
                        .pb = p[1],
                        .pc = p[2],
                        .color = clipped.color,
                        .depth = clipped.depth
                    });
                }
            }
        }

        // sort: far triangles first
        std.sort.pdq(Triangle, self.tri_buffer.items, {}, struct {
            fn lessThan(_: void, a: Triangle, b: Triangle) bool {
                return a.depth > b.depth;
            }
        }.lessThan);

        const f_width  = @as(f32, @floatFromInt(self.size.x));
        const f_height = @as(f32, @floatFromInt(self.size.y));

        const planes = [4]Plane{
            .{ .point = .{ 0.0,    0.0,     0.0 }, .normal = .{  0.0,  1.0, 0.0 } }, // top
            .{ .point = .{ 0.0,    f_height, 0.0 }, .normal = .{  0.0, -1.0, 0.0 } }, // bottom
            .{ .point = .{ 0.0,    0.0,     0.0 }, .normal = .{  1.0,  0.0, 0.0 } }, // left
            .{ .point = .{ f_width, 0.0,    0.0 }, .normal = .{ -1.0,  0.0, 0.0 } }, // right
        };

        for (self.tri_buffer.items) |tri| {
            self.tri_raster_list.clearRetainingCapacity();
            try self.tri_raster_list.append(self.allocator, tri);

            for (0..4) |p| {
                const tris_to_process = self.tri_raster_list.items.len;

                for (0..tris_to_process) |i| {
                    const test_tri = self.tri_raster_list.items[i];

                    const clip = switch (p) {
                        0 => math.clipTriangleAgainstPlane(planes[0].point, planes[0].normal, test_tri),
                        1 => math.clipTriangleAgainstPlane(planes[1].point, planes[1].normal, test_tri),
                        2 => math.clipTriangleAgainstPlane(planes[2].point, planes[2].normal, test_tri),
                        3 => math.clipTriangleAgainstPlane(planes[3].point, planes[3].normal, test_tri),

                        else => unreachable,
                    };

                    for (0..clip.n) |w| {
                        const clipped = if (w == 0) clip.t1.? else clip.t2.?;
                        try self.tri_raster_list.append(self.allocator, clipped);
                    }
                }

                self.tri_raster_list.replaceRangeAssumeCapacity(0, tris_to_process, &.{});
            }

            for (self.tri_raster_list.items) |final_tri| {
                self.drawTriangle(final_tri.pa, final_tri.pb, final_tri.pc, final_tri.color);
                //self.drawTriangleWireframe(final_tri.pa, final_tri.pb, final_tri.pc, 0xFF_00_00_00);
            }
        }
    }

    inline fn drawPoint(self: *Renderer, x: f32, y: f32, color: ?u32) void {
        const fw = @as(f32, @floatFromInt(self.size.x));
        const fh = @as(f32, @floatFromInt(self.size.y));
        if (x < 0 or y < 0 or x >= fw or y >= fh) return;

        const ix = @as(usize, @intFromFloat(x));
        const iy = @as(usize, @intFromFloat(y));
        const width_usize = @as(usize, @intCast(self.size.x));

        const idx = iy * width_usize + ix;

        if (idx >= self.framebuffer.len) return;
        self.framebuffer[idx] = color orelse 0xFF_FF_FF_FF;
    }

    fn drawLine(self: *Renderer, p0: Vec3_SIMD, p1: Vec3_SIMD, color: ?u32) void {
        var x0 = @as(i32, @intFromFloat(p0[0]));
        var y0 = @as(i32, @intFromFloat(p0[1]));
        const x1 = @as(i32, @intFromFloat(p1[0]));
        const y1 = @as(i32, @intFromFloat(p1[1]));

        const dx = @as(i32, if (x0 < x1) x1 - x0 else x0 - x1);
        const dy = @as(i32, if (y0 < y1) y1 - y0 else y0 - y1);
        const sx = @as(i32, if (x0 < x1) 1 else -1);
        const sy = @as(i32, if (y0 < y1) 1 else -1);
        var err = dx - dy;

        while (true) {
            self.drawPoint(
                @as(f32, @floatFromInt(x0)),
                @as(f32, @floatFromInt(y0)),
                color
            );
            if (x0 == x1 and y0 == y1) break;

            const e2 = 2 * err;
            if (e2 > -dy) { err -= dy; x0 += sx; }
            if (e2 <  dx) { err += dx; y0 += sy; }
        }
    }

    fn drawTriangle(self: *Renderer, p0: Vec3_SIMD, p1: Vec3_SIMD, p2: Vec3_SIMD, color: ?u32) void {
        var a = p0;
        var b = p1;
        var c = p2;

        if (a[1] > b[1]) std.mem.swap(Vec3_SIMD, &a, &b);
        if (b[1] > c[1]) std.mem.swap(Vec3_SIMD, &b, &c);
        if (a[1] > b[1]) std.mem.swap(Vec3_SIMD, &a, &b);

        const y_top    = a[1];
        const y_mid    = b[1];
        const y_bottom = c[1];

        if (y_top == y_bottom) return;

        const ac = (c[0] - a[0]) / (y_bottom - y_top);
        const ab = if (y_mid != y_top)   (b[0] - a[0]) / (y_mid - y_top)    else 0.0;
        const bc = if (y_bottom != y_mid) (c[0] - b[0]) / (y_bottom - y_mid) else 0.0;

        { // upper half
            const y_start = @as(i32, @intFromFloat(@ceil(y_top)));
            const y_end   = @as(i32, @intFromFloat(@ceil(y_mid)));

            var y = y_start;
            while (y < y_end) : (y += 1) {
                const t = @as(f32, @floatFromInt(y));
                var xa = a[0] + (t - y_top) * ac;
                var xb = a[0] + (t - y_top) * ab;
                if (xa > xb) std.mem.swap(f32, &xa, &xb);

                const x0 = @as(i32, @intFromFloat(@ceil(xa)));
                const x1 = @as(i32, @intFromFloat(@floor(xb))) + 1;

                var x: i32 = x0;
                while (x < x1) : (x += 1) {
                    self.drawPoint(@floatFromInt(x), t, color);
                }
            }
        }

        { // lower half
            const y_start = @as(i32, @intFromFloat(@ceil(y_mid)));
            const y_end   = @as(i32, @intFromFloat(@ceil(y_bottom)));

            var y = y_start;
            while (y < y_end) : (y += 1) {
                const t = @as(f32, @floatFromInt(y));
                var xa = a[0] + (t - y_top) * ac;
                var xb = b[0] + (t - y_mid) * bc;
                if (xa > xb) std.mem.swap(f32, &xa, &xb);

                const x0 = @as(i32, @intFromFloat(@ceil(xa)));
                const x1 = @as(i32, @intFromFloat(@floor(xb))) + 1;

                var x: i32 = x0;
                while (x < x1) : (x += 1) {
                    self.drawPoint(@floatFromInt(x), t, color);
                }
            }
        }
    }

    fn drawTriangleWireframe(self: *Renderer, p0: Vec3_SIMD, p1: Vec3_SIMD, p2: Vec3_SIMD, color: ?u32) void {
        self.drawLine(p0, p1, color);
        self.drawLine(p1, p2, color);
        self.drawLine(p2, p0, color);
    }

    pub fn visualizeAxes(self: *Renderer) void {
        const projection_matrix = self.camera.getProjectionMatrix();
        const view_matrix = self.camera.getViewMatrix();

        const sx = 0.5 * @as(f32, @floatFromInt(self.size.x));
        const sy = 0.5 * @as(f32, @floatFromInt(self.size.y));

        // this changes the axis line length
        const axis_length = @as(f32, 2.0);

        // axes in world space
        const world_origin = Vec3_SIMD{ 0.0, 0.0, 0.0 };
        const world_x = Vec3_SIMD{ axis_length, 0.0, 0.0 };
        const world_y = Vec3_SIMD{ 0.0, axis_length, 0.0 };
        const world_z = Vec3_SIMD{ 0.0, 0.0, axis_length };

        // view space
        const view_origin = math.multiplyMatrixVector(view_matrix, world_origin);
        const view_x = math.multiplyMatrixVector(view_matrix, world_x);
        const view_y = math.multiplyMatrixVector(view_matrix, world_y);
        const view_z = math.multiplyMatrixVector(view_matrix, world_z);

        const LineClipper = struct {
            fn drawClippedLine(
                r: *Renderer,
                p0_view: Vec3_SIMD,
                p1_view: Vec3_SIMD,
                proj: Mat4,
                scale_x: f32,
                scale_y: f32,
                color: u32
            ) void {
                const near_z = 0.1;
                const d0 = p0_view[2] - near_z;
                const d1 = p1_view[2] - near_z;

                var start = p0_view;
                var end = p1_view;

                // it's behind plane, discard
                if (d0 < 0.0 and d1 < 0.0) return;

                if (d0 < 0.0) { // clip start point if behind near plane
                    start = math.vectorIntersectPlane(
                        Vec3_SIMD{ 0.0, 0.0, near_z },
                        Vec3_SIMD{ 0.0, 0.0, 1.0 },
                        p0_view,
                        p1_view
                    );
                } else if (d1 < 0.0) { // clip end point if behind near plane
                    end = math.vectorIntersectPlane(
                        Vec3_SIMD{ 0.0, 0.0, near_z },
                        Vec3_SIMD{ 0.0, 0.0, 1.0 },
                        p0_view,
                        p1_view
                    );
                }

                const proj_start = math.multiplyMatrixVector(proj, start);
                const proj_end   = math.multiplyMatrixVector(proj, end);

                // map to screen space
                const screen_start = Vec3_SIMD{ (proj_start[0] + 1.0) * scale_x, (1.0 - proj_start[1]) * scale_y, 0.0 };
                const screen_end   = Vec3_SIMD{ (proj_end[0] + 1.0) * scale_x,   (1.0 - proj_end[1]) * scale_y,   0.0 };

                r.drawLine(screen_start, screen_end, color);
            }
        };

        // draw
        LineClipper.drawClippedLine(self, view_origin, view_x, projection_matrix, sx, sy, 0xFF_FF_00_00); // x = red
        LineClipper.drawClippedLine(self, view_origin, view_y, projection_matrix, sx, sy, 0xFF_00_FF_00); // y = green
        LineClipper.drawClippedLine(self, view_origin, view_z, projection_matrix, sx, sy, 0xFF_00_00_FF); // z = blue
    }
};
