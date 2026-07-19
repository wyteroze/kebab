// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const math = @import("../math.zig");
const types = @import("types.zig");
const RenderTarget = @import("RenderTarget.zig").RenderTarget;
const ImageData = @import("../ImageData.zig").ImageData;
const Font = @import("../ui/Font.zig").Font;

const Rect = types.Rect;

fn blend(target: *RenderTarget, x: i32, y: i32, color: u32, clip: ?Rect) void {
    if (clip) |c| {
        if (x < c.x or y < c.y or x >= c.x + c.w or y >= c.y + c.h) return;
    }

    target.blendPixel(x, y, color);
}

const Bounds = struct { x0: i32, y0: i32, x1: i32, y1: i32 };

fn clipBounds(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, clip: ?Rect) ?Bounds {
    var x0 = math.max(0, x);
    var y0 = math.max(0, y);
    var x1 = math.min(@as(i32, @intCast(target.size_x)), x + w);
    var y1 = math.min(@as(i32, @intCast(target.size_y)), y + h);

    if (clip) |c| {
        x0 = math.max(x0, c.x);
        y0 = math.max(y0, c.y);
        x1 = math.min(x1, c.x + c.w);
        y1 = math.min(y1, c.y + c.h);
    }

    if (x1 <= x0 or y1 <= y0) return null;
    return .{ .x0 = x0, .y0 = y0, .x1 = x1, .y1 = y1 };
}

pub fn rect(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, color: u32, clip: ?Rect) void {
    const b = clipBounds(target, x, y, w, h, clip) orelse return;

    if ((color >> 24) == 0xFF) {
        const pixels = target.getPixels();
        const pitch = target.pitchPixels();

        var py = b.y0;
        while (py < b.y1) : (py += 1) {
            const row = @as(usize, @intCast(py)) * pitch;
            @memset(pixels[row + @as(usize, @intCast(b.x0)) .. row + @as(usize, @intCast(b.x1))], color);
        }

        return;
    }

    var py = b.y0;
    while (py < b.y1) : (py += 1) {
        var px = b.x0;
        while (px < b.x1) : (px += 1) target.blendPixel(px, py, color);
    }
}

pub fn strokeRect(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, thickness: i32, color: u32, clip: ?Rect, top: bool, bottom: bool, left: bool, right: bool) void {
    if (w <= 0 or h <= 0 or thickness <= 0) return;
    const t = math.min(thickness, math.min(w, h));

    if (top) rect(target, x, y, w, t, color, clip);
    if (bottom) rect(target, x, y + h - t, w, t, color, clip);
    if (left) rect(target, x, y + t, t, h - 2 * t, color, clip);
    if (right) rect(target, x + w - t, y + t, t, h - 2 * t, color, clip);
}

pub fn roundedRect(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, radius: i32, color: u32, clip: ?Rect) void {
    if (w <= 0 or h <= 0) return;
    const r = math.min(radius, math.min(@divTrunc(w, 2), @divTrunc(h, 2)));

    const b = clipBounds(target, x, y, w, h, clip) orelse return;

    var ay = b.y0;
    while (ay < b.y1) : (ay += 1) {
        const py = ay - y;
        var ax = b.x0;
        while (ax < b.x1) : (ax += 1) {
            const px = ax - x;

            const cx = if (px < r) r else if (px >= w - r) w - 1 - r else px;
            const cy = if (py < r) r else if (py >= h - r) h - 1 - r else py;
            const dx = px - cx;
            const dy = py - cy;
            if (dx * dx + dy * dy > r * r) continue;

            target.blendPixel(ax, ay, color);
        }
    }
}

pub fn image(target: *RenderTarget, img: *const ImageData, x: i32, y: i32, w: i32, h: i32, tint: ?u32, clip: ?Rect) void {
    if (w <= 0 or h <= 0) return;
    const b = clipBounds(target, x, y, w, h, clip) orelse return;

    var ay = b.y0;
    while (ay < b.y1) : (ay += 1) {
        const dy = @as(u32, @intCast(ay - y));
        const py = @min((dy * img.height) / @as(u32, @intCast(h)), img.height - 1);

        var ax = b.x0;
        while (ax < b.x1) : (ax += 1) {
            const dx = @as(u32, @intCast(ax - x));
            const px = @min((dx * img.width) / @as(u32, @intCast(w)), img.width - 1);
            const pix = if (tint) |t| multiply(img.samplePixel(px, py), t) else img.samplePixel(px, py);

            target.blendPixel(ax, ay, pix);
        }
    }
}

fn multiply(a: u32, b: u32) u32 {
    const out_a = ((a >> 24) & 0xFF) * ((b >> 24) & 0xFF) / 255;
    const out_r = ((a >> 16) & 0xFF) * ((b >> 16) & 0xFF) / 255;
    const out_g = ((a >> 8) & 0xFF) * ((b >> 8) & 0xFF) / 255;
    const out_b = (a & 0xFF) * (b & 0xFF) / 255;

    return (out_a << 24) | (out_r << 16) | (out_g << 8) | out_b;
}

// Draws the glyph and returns its horizontal advance. (0 if the glyph is missing)
pub fn glyph(target: *RenderTarget, font: *Font, codepoint: u21, x: i32, y: i32, foreground: u32, clip: ?Rect, scale: u32) u32 {
    const g = font.glyph(codepoint) orelse return 0;
    const s = @as(usize, @intCast(@max(scale, 1)));
    const size_x = @as(usize, @intCast(g.size_x));
    const size_y = @as(usize, @intCast(g.size_y));
    const fg_alpha = foreground >> 24;

    for (0..size_y) |gy| {
        for (0..size_x) |gx| {
            const texel = font.sheet.samplePixel(
                @as(u32, @intCast(g.pos_x + gx)),
                @as(u32, @intCast(g.pos_y + gy)),
            );
            const alpha = texel >> 24;
            if (alpha == 0) continue;

            const out_alpha = alpha * fg_alpha / 255;
            const color = (out_alpha << 24) | (foreground & 0x00FFFFFF);

            for (0..s) |sy| {
                for (0..s) |sx| {
                    blend(
                        target,
                        x + @as(i32, @intCast(gx * s + sx)),
                        y + @as(i32, @intCast(gy * s + sy)),
                        color,
                        clip
                    );
                }
            }
        }
    }

    return g.advance * @max(scale, 1);
}

pub fn text(target: *RenderTarget, font: *Font, x: i32, y: i32, str: []const u8, color: u32, clip: ?Rect, scale: u32) void {
    const view = std.unicode.Utf8View.init(str) catch return;

    var pos: i32 = x;
    var iter = view.iterator();
    while (iter.nextCodepoint()) |codepoint| {
        pos += @as(i32, @intCast(glyph(target, font, codepoint, pos, y, color, clip, scale)));
    }
}

pub fn line(target: *RenderTarget, x0_: i32, y0_: i32, x1: i32, y1: i32, color: u32, clip: ?Rect) void {
    var x0 = x0_;
    var y0 = y0_;
    const dx = if (x0 < x1) x1 - x0 else x0 - x1;
    const dy = if (y0 < y1) y1 - y0 else y0 - y1;
    const sx: i32 = if (x0 < x1) 1 else -1;
    const sy: i32 = if (y0 < y1) 1 else -1;
    var err = dx - dy;

    while (true) {
        blend(target, x0, y0, color, clip);
        if (x0 == x1 and y0 == y1) break;
        const e2 = 2 * err;
        if (e2 > -dy) { err -= dy; x0 += sx; }
        if (e2 < dx) { err += dx; y0 += sy; }
    }
}

fn edge(ax: f32, ay: f32, bx: f32, by: f32, px: f32, py: f32) f32 {
    return (px - ax) * (by - ay) - (py - ay) * (bx - ax);
}

pub fn fillTriangle(target: *RenderTarget, ax: i32, ay: i32, bx: i32, by: i32, cx: i32, cy: i32, color: u32, clip: ?Rect) void {
    const minx = @min(ax, @min(bx, cx));
    const maxx = @max(ax, @max(bx, cx));
    const miny = @min(ay, @min(by, cy));
    const maxy = @max(ay, @max(by, cy));

    const fax: f32 = @floatFromInt(ax); const fay: f32 = @floatFromInt(ay);
    const fbx: f32 = @floatFromInt(bx); const fby: f32 = @floatFromInt(by);
    const fcx: f32 = @floatFromInt(cx); const fcy: f32 = @floatFromInt(cy);

    const area = edge(fax, fay, fbx, fby, fcx, fcy);
    if (area == 0) return;

    const b = clipBounds(target, minx, miny, maxx - minx + 1, maxy - miny + 1, clip) orelse return;

    var py = b.y0;
    while (py < b.y1) : (py += 1) {
        var px = b.x0;
        while (px < b.x1) : (px += 1) {
            const fx = @as(f32, @floatFromInt(px)) + 0.5;
            const fy = @as(f32, @floatFromInt(py)) + 0.5;
            const w0 = edge(fbx, fby, fcx, fcy, fx, fy);
            const w1 = edge(fcx, fcy, fax, fay, fx, fy);
            const w2 = edge(fax, fay, fbx, fby, fx, fy);
            const inside = if (area > 0) (w0 >= 0 and w1 >= 0 and w2 >= 0)
                           else (w0 <= 0 and w1 <= 0 and w2 <= 0);

            if (inside) target.blendPixel(px, py, color);
        }
    }
}

pub fn circle(target: *RenderTarget, cx: i32, cy: i32, radius: i32, color: u32, clip: ?Rect) void {
    if (radius <= 0) return;
    const r2 = radius * radius;
    const b = clipBounds(target, cx - radius, cy - radius, 2 * radius + 1, 2 * radius + 1, clip) orelse return;

    var y = b.y0;
    while (y < b.y1) : (y += 1) {
        const dy = y - cy;
        var x = b.x0;

        while (x < b.x1) : (x += 1) {
            const dx = x - cx;
            if (dx * dx + dy * dy <= r2) target.blendPixel(x, y, color);
        }
    }
}

fn angleBetween(ang: f32, start: f32, end: f32) bool {
    if (start <= end) return ang >= start and ang <= end;
    return ang >= start or ang <= end;
}

/// Especially useful for pie charts.
pub fn wedge(target: *RenderTarget, cx: i32, cy: i32, radius: i32, start: f32, end: f32, color: u32, clip: ?Rect) void {
    if (radius <= 0) return;
    const r2 = radius * radius;

    const tau = std.math.tau;
    var a0 = @mod(start, tau); if (a0 < 0) a0 += tau;
    var a1 = @mod(end, tau);   if (a1 < 0) a1 += tau;

    const b = clipBounds(target, cx - radius, cy - radius, 2 * radius + 1, 2 * radius + 1, clip) orelse return;

    var y = b.y0;
    while (y < b.y1) : (y += 1) {
        const dy = y - cy;
        var x = b.x0;
        while (x < b.x1) : (x += 1) {
            const dx = x - cx;
            if (dx * dx + dy * dy > r2) continue;

            var ang = std.math.atan2(@as(f32, @floatFromInt(dy)), @as(f32, @floatFromInt(dx)));
            if (ang < 0) ang += tau;
            if (angleBetween(ang, a0, a1)) target.blendPixel(x, y, color);
        }
    }
}
