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

pub fn rect(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, color: u32, clip: ?Rect) void {
    const x0 = math.max(0, x);
    const y0 = math.max(0, y);
    const x1 = math.min(@as(i32, @intCast(target.size_x)), x + w);
    const y1 = math.min(@as(i32, @intCast(target.size_y)), y + h);

    var py = y0;
    while (py < y1) : (py += 1) {
        var px = x0;
        while (px < x1) : (px += 1) blend(target, px, py, color, clip);
    }
}

pub fn roundedRect(target: *RenderTarget, x: i32, y: i32, w: i32, h: i32, radius: i32, color: u32, clip: ?Rect) void {
    if (w <= 0 or h <= 0) return;
    const r = math.min(radius, math.min(@divTrunc(w, 2), @divTrunc(h, 2)));

    var py: i32 = 0;
    while (py < h) : (py += 1) {
        var px: i32 = 0;
        while (px < w) : (px += 1) {
            const cx = if (px < r) r else if (px >= w - r) w - 1 - r else px;
            const cy = if (py < r) r else if (py >= h - r) h - 1 - r else py;
            const dx = px - cx;
            const dy = py - cy;
            if (dx * dx + dy * dy > r * r) continue;

            blend(target, x + px, y + py, color, clip);
        }
    }
}

pub fn image(target: *RenderTarget, img: *const ImageData, x: i32, y: i32, w: i32, h: i32, clip: ?Rect) void {
    if (w <= 0 or h <= 0) return;

    var py: i32 = 0;
    while (py < h) : (py += 1) {
        var px: i32 = 0;
        while (px < w) : (px += 1) {
            const u = (@as(f32, @floatFromInt(px)) + 0.5) / @as(f32, @floatFromInt(w));
            const v = (@as(f32, @floatFromInt(py)) + 0.5) / @as(f32, @floatFromInt(h));

            blend(target, x + px, y + py, img.sample(u, v), clip);
        }
    }
}

// Draws the glyph and returns its horizontal advance. (0 if the glyph is missing)
pub fn glyph(target: *RenderTarget, font: *Font, codepoint: u21, x: i32, y: i32, foreground: u32, clip: ?Rect) u32 {
    const g = font.glyph(codepoint) orelse return 0;
    const size_x = @as(usize, @intCast(g.size_x));
    const size_y = @as(usize, @intCast(g.size_y));
    const fg_alpha = foreground >> 24;

    for (0..size_y) |gy| {
        for (0..size_x) |gx| {
            const texel = font.sheet.samplePixel(
                @as(u32, @intCast(g.pos_x + @as(u32, @intCast(gx)))),
                @as(u32, @intCast(g.pos_y + @as(u32, @intCast(gy)))),
            );
            const alpha = texel >> 24;
            if (alpha == 0) continue;

            const out_alpha = alpha * fg_alpha / 255;
            blend(target, x + @as(i32, @intCast(gx)), y + @as(i32, @intCast(gy)), (out_alpha << 24) | (foreground & 0x00FFFFFF), clip);
        }
    }

    return g.advance;
}

pub fn text(target: *RenderTarget, font: *Font, x: i32, y: i32, str: []const u8, color: u32, clip: ?Rect) void {
    const view = std.unicode.Utf8View.init(str) catch return;

    var pos: i32 = x;
    var iter = view.iterator();
    while (iter.nextCodepoint()) |codepoint| {
        pos += @as(i32, @intCast(glyph(target, font, codepoint, pos, y, color, clip)));
    }
}
