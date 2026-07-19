// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const engine_types = @import("../types.zig");
const types = @import("types.zig");
const RenderTarget = @import("RenderTarget.zig").RenderTarget;
const ImageData = @import("../ImageData.zig").ImageData;

const Vec3 = engine_types.Vec3;
const Triangle = types.Triangle;
const Vertex = types.Vertex;
const DrawCommand = types.DrawCommand;

/// Consume the pipeline's DrawList into the target.
pub fn flush(target: *RenderTarget, tris: []const Triangle, commands: []const DrawCommand) void {
    for (commands) |cmd| {
        const slice = tris[cmd.first .. cmd.first + cmd.count];
        if (cmd.texture) |tex| {
            for (slice) |tri| texturedTriangle(target, tri, tex.*);
        } else {
            for (slice) |tri| triangle(target, tri.pa.position, tri.pb.position, tri.pc.position, tri.color);
        }
    }
}

pub fn point(target: *RenderTarget, x: f32, y: f32, color: ?u32) void {
    const fw = @as(f32, @floatFromInt(target.size_x));
    const fh = @as(f32, @floatFromInt(target.size_y));
    if (x < 0 or y < 0 or x >= fw or y >= fh) return;
    target.setPixel(@intFromFloat(x), @intFromFloat(y), color orelse 0xFF_FF_FF_FF);
}

pub fn line(target: *RenderTarget, p0: Vec3, p1: Vec3, color: ?u32) void {
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
        point(target, @floatFromInt(x0), @floatFromInt(y0), color);
        if (x0 == x1 and y0 == y1) break;

        const e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x0 += sx; }
        if (e2 < dx) { err += dx; y0 += sy; }
    }
}

pub fn triangle(target: *RenderTarget, p0: Vec3, p1: Vec3, p2: Vec3, color: ?u32) void {
    var a = p0;
    var b = p1;
    var c = p2;

    if (a[1] > b[1]) std.mem.swap(Vec3, &a, &b);
    if (b[1] > c[1]) std.mem.swap(Vec3, &b, &c);
    if (a[1] > b[1]) std.mem.swap(Vec3, &a, &b);

    const y_top = a[1];
    const y_mid = b[1];
    const y_bottom = c[1];

    if (y_top == y_bottom) return;

    const ac = (c[0] - a[0]) / (y_bottom - y_top);
    const ab = if (y_mid != y_top) (b[0] - a[0]) / (y_mid - y_top) else 0.0;
    const bc = if (y_bottom != y_mid) (c[0] - b[0]) / (y_bottom - y_mid) else 0.0;

    { // upper half
        const y_start = @as(i32, @intFromFloat(@ceil(y_top)));
        const y_end = @as(i32, @intFromFloat(@ceil(y_mid)));

        var y = y_start;
        while (y < y_end) : (y += 1) {
            const t = @as(f32, @floatFromInt(y));
            var xa = a[0] + (t - y_top) * ac;
            var xb = a[0] + (t - y_top) * ab;
            if (xa > xb) std.mem.swap(f32, &xa, &xb);

            const x0 = @as(i32, @intFromFloat(@ceil(xa)));
            const x1 = @as(i32, @intFromFloat(@floor(xb))) + 1;

            var x: i32 = x0;
            while (x < x1) : (x += 1) point(target, @floatFromInt(x), t, color);
        }
    }

    { // lower half
        const y_start = @as(i32, @intFromFloat(@ceil(y_mid)));
        const y_end = @as(i32, @intFromFloat(@ceil(y_bottom)));

        var y = y_start;
        while (y < y_end) : (y += 1) {
            const t = @as(f32, @floatFromInt(y));
            var xa = a[0] + (t - y_top) * ac;
            var xb = b[0] + (t - y_mid) * bc;
            if (xa > xb) std.mem.swap(f32, &xa, &xb);

            const x0 = @as(i32, @intFromFloat(@ceil(xa)));
            const x1 = @as(i32, @intFromFloat(@floor(xb))) + 1;

            var x: i32 = x0;
            while (x < x1) : (x += 1) point(target, @floatFromInt(x), t, color);
        }
    }
}

pub fn wireframe(target: *RenderTarget, p0: Vec3, p1: Vec3, p2: Vec3, color: ?u32) void {
    line(target, p0, p1, color);
    line(target, p1, p2, color);
    line(target, p2, p0, color);
}

/// Pixels between perspective divides. If resolution
/// is large this may need to be turned down.
const subspan_len: i32 = 16;

fn texturedSpan(
    target: *RenderTarget,
    depth: []f32,
    img_data: ImageData,
    y: i32,
    ax: i32,
    bx: i32,
    su: f32, sv: f32, sw: f32,
    eu: f32, ev: f32, ew: f32,
) void {
    if (y < 0 or y >= @as(i32, @intCast(target.size_y))) return;
    if (bx <= ax) return;

    const x_start = @max(ax, 0);
    const x_end = @min(bx, @as(i32, @intCast(target.size_x)));
    if (x_end <= x_start) return;

    const pixels = target.getPixels();
    const row = @as(usize, @intCast(y)) * target.pitchPixels();
    const depth_row = @as(usize, @intCast(y)) * target.size_x;

    const inv_span = 1.0 / @as(f32, @floatFromInt(bx - ax));
    const du = eu - su;
    const dv = ev - sv;
    const dw = ew - sw;

    var x = x_start;
    while (x < x_end) {
        const chunk_end = @min(x + subspan_len, x_end);

        const t0 = @as(f32, @floatFromInt(x - ax)) * inv_span;
        const t1 = @as(f32, @floatFromInt(chunk_end - ax)) * inv_span;

        const w0 = sw + dw * t0;
        const w1 = sw + dw * t1;
        const inv_w0 = if (w0 != 0) 1.0 / w0 else 0;
        const inv_w1 = if (w1 != 0) 1.0 / w1 else 0;

        var u = (su + du * t0) * inv_w0;
        var v = (sv + dv * t0) * inv_w0;
        var w = w0;

        const inv_n = 1.0 / @as(f32, @floatFromInt(chunk_end - x));
        const u_step = ((su + du * t1) * inv_w1 - u) * inv_n;
        const v_step = ((sv + dv * t1) * inv_w1 - v) * inv_n;
        const w_step = (w1 - w0) * inv_n;

        while (x < chunk_end) : (x += 1) {
            const idx = depth_row + @as(usize, @intCast(x));
            if (w > depth[idx]) {
                pixels[row + @as(usize, @intCast(x))] = img_data.sample(u, v);
                depth[idx] = w;
            }

            u += u_step;
            v += v_step;
            w += w_step;
        }
    }
}

// I'm sorry
pub fn texturedTriangle(target: *RenderTarget, tri: Triangle, img_data: ImageData) void {
    const depth = target.depthbuffer orelse return;

    var pa = tri.pa;
    var pb = tri.pb;
    var pc = tri.pc;

    if (pb.position[1] < pa.position[1]) std.mem.swap(Vertex, &pa, &pb);
    if (pc.position[1] < pa.position[1]) std.mem.swap(Vertex, &pa, &pc);
    if (pc.position[1] < pb.position[1]) std.mem.swap(Vertex, &pb, &pc);

    const x1 = @as(i32, @intFromFloat(pa.position[0]));
    const y1 = @as(i32, @intFromFloat(pa.position[1]));
    const tu1 = pa.uv[0];
    const tv1 = pa.uv[1];
    const tw1 = pa.position[2];

    const x2 = @as(i32, @intFromFloat(pb.position[0]));
    const y2 = @as(i32, @intFromFloat(pb.position[1]));
    const tu2 = pb.uv[0];
    const tv2 = pb.uv[1];
    const tw2 = pb.position[2];

    const x3 = @as(i32, @intFromFloat(pc.position[0]));
    const y3 = @as(i32, @intFromFloat(pc.position[1]));
    const tu3 = pc.uv[0];
    const tv3 = pc.uv[1];
    const tw3 = pc.position[2];

    // top half
    var dy1: i32 = y2 - y1;
    var dx1: i32 = x2 - x1;
    var dv1: f32 = tv2 - tv1;
    var du1: f32 = tu2 - tu1;
    var dw1: f32 = tw2 - tw1;

    const dy2 = y3 - y1;
    const dx2 = x3 - x1;
    const dv2 = tv3 - tv1;
    const du2 = tu3 - tu1;
    const dw2 = tw3 - tw1;

    var dax_step: f32 = 0;
    var dbx_step: f32 = 0;
    var du1_step: f32 = 0;
    var dv1_step: f32 = 0;
    var dw1_step: f32 = 0;
    var du2_step: f32 = 0;
    var dv2_step: f32 = 0;
    var dw2_step: f32 = 0;

    if (dy1 != 0) dax_step = @as(f32, @floatFromInt(dx1)) / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy2 != 0) dbx_step = @as(f32, @floatFromInt(dx2)) / @as(f32, @floatFromInt(@abs(dy2)));

    if (dy1 != 0) du1_step = du1 / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy1 != 0) dv1_step = dv1 / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy1 != 0) dw1_step = dw1 / @as(f32, @floatFromInt(@abs(dy1)));

    if (dy2 != 0) du2_step = du2 / @as(f32, @floatFromInt(@abs(dy2)));
    if (dy2 != 0) dv2_step = dv2 / @as(f32, @floatFromInt(@abs(dy2)));
    if (dy2 != 0) dw2_step = dw2 / @as(f32, @floatFromInt(@abs(dy2)));

    if (dy1 != 0) {
        var i: i32 = y1;
        while (i <= y2) : (i += 1) {
            const fi = @as(f32, @floatFromInt(i - y1));

            var ax: i32 = x1 + @as(i32, @intFromFloat(fi * dax_step));
            var bx: i32 = x1 + @as(i32, @intFromFloat(fi * dbx_step));

            var tex_su: f32 = tu1 + fi * du1_step;
            var tex_sv: f32 = tv1 + fi * dv1_step;
            var tex_sw: f32 = tw1 + fi * dw1_step;

            var tex_eu: f32 = tu1 + fi * du2_step;
            var tex_ev: f32 = tv1 + fi * dv2_step;
            var tex_ew: f32 = tw1 + fi * dw2_step;

            if (ax > bx) {
                std.mem.swap(i32, &ax, &bx);
                std.mem.swap(f32, &tex_su, &tex_eu);
                std.mem.swap(f32, &tex_sv, &tex_ev);
                std.mem.swap(f32, &tex_sw, &tex_ew);
            }

            texturedSpan(
                target, depth, img_data, i, ax, bx,
                tex_su, tex_sv, tex_sw,
                tex_eu, tex_ev, tex_ew,
            );
        }
    }

    // bottom half
    dy1 = y3 - y2;
    dx1 = x3 - x2;
    dv1 = tv3 - tv2;
    du1 = tu3 - tu2;
    dw1 = tw3 - tw2;

    if (dy1 != 0) dax_step = @as(f32, @floatFromInt(dx1)) / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy2 != 0) dbx_step = @as(f32, @floatFromInt(dx2)) / @as(f32, @floatFromInt(@abs(dy2)));

    du1_step = 0;
    dv1_step = 0;
    if (dy1 != 0) du1_step = du1 / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy1 != 0) dv1_step = dv1 / @as(f32, @floatFromInt(@abs(dy1)));
    if (dy1 != 0) dw1_step = dw1 / @as(f32, @floatFromInt(@abs(dy1)));

    if (dy1 != 0) {
        var i: i32 = y2;
        while (i <= y3) : (i += 1) {
            const fi_top = @as(f32, @floatFromInt(i - y2));
            const fi_bot = @as(f32, @floatFromInt(i - y1));

            var ax: i32 = x2 + @as(i32, @intFromFloat(fi_top * dax_step));
            var bx: i32 = x1 + @as(i32, @intFromFloat(fi_bot * dbx_step));

            var tex_su: f32 = tu2 + fi_top * du1_step;
            var tex_sv: f32 = tv2 + fi_top * dv1_step;
            var tex_sw: f32 = tw2 + fi_top * dw1_step;

            var tex_eu: f32 = tu1 + fi_bot * du2_step;
            var tex_ev: f32 = tv1 + fi_bot * dv2_step;
            var tex_ew: f32 = tw1 + fi_bot * dw2_step;

            if (ax > bx) {
                std.mem.swap(i32, &ax, &bx);
                std.mem.swap(f32, &tex_su, &tex_eu);
                std.mem.swap(f32, &tex_sv, &tex_ev);
                std.mem.swap(f32, &tex_sw, &tex_ew);
            }

            texturedSpan(
                target, depth, img_data, i, ax, bx,
                tex_su, tex_sv, tex_sw,
                tex_eu, tex_ev, tex_ew,
            );
        }
    }
}
