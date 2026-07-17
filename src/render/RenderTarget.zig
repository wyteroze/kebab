// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const engine_types = @import("../types.zig");
const perf = @import("../profile/perf.zig");

pub const RenderTarget = struct {
    allocator: std.mem.Allocator,
    window: sdl3.video.Window,
    canvas: sdl3.surface.Surface,
    depthbuffer: ?[]f32,
    size_x: usize,
    size_y: usize,
    scale: f32,
    opaque_bg: bool,

    pub fn init(
        allocator: std.mem.Allocator,
        window: sdl3.video.Window,
        size_x: usize,
        size_y: usize,
        scale: f32,
        want_depth: bool,
        opaque_bg: bool,
    ) !RenderTarget {
        const canvas = try sdl3.surface.Surface.init(size_x, size_y, .array_bgra_32);
        try canvas.setBlendMode(.none);

        const depthbuffer = if (want_depth)
            try allocator.alloc(f32, size_x * size_y)
        else
            null;

        return .{
            .allocator = allocator,
            .window = window,
            .canvas = canvas,
            .depthbuffer = depthbuffer,
            .size_x = size_x,
            .size_y = size_y,
            .scale = scale,
            .opaque_bg = opaque_bg,
        };
    }

    pub fn deinit(self: *RenderTarget) void {
        self.canvas.deinit();
        if (self.depthbuffer) |db| self.allocator.free(db);
    }

    pub fn resize(self: *RenderTarget, size_x: usize, size_y: usize) !void {
        const canvas = try sdl3.surface.Surface.init(size_x, size_y, .array_bgra_32);
        try canvas.setBlendMode(.none);
        self.canvas.deinit();
        self.canvas = canvas;

        if (self.depthbuffer != null) {
            self.allocator.free(self.depthbuffer.?);
            self.depthbuffer = try self.allocator.alloc(f32, size_x * size_y);
        }

        self.size_x = size_x;
        self.size_y = size_y;
    }

    pub fn present(self: RenderTarget) !void {
        const surface = try sdl3.video.Window.getSurface(self.window);

        perf.start("blit"); {
            try self.canvas.blitScaled(null, surface, null, .nearest);
        } perf.stop();

        perf.start("copy"); {
            try self.window.updateSurface();
        } perf.stop();
    }

    pub fn clear(self: *RenderTarget, color: u32, clear_depth: bool) void {
        @memset(self.getPixels(), color);
        if (clear_depth) if (self.depthbuffer) |db| @memset(db, 0.0);
    }

    pub inline fn getPixels(self: RenderTarget) []u32 {
        const bytes = self.canvas.getPixels().?;
        const ptr: [*]u32 = @ptrCast(@alignCast(bytes.ptr));
        return ptr[0 .. bytes.len / @sizeOf(u32)];
    }

    inline fn pitchPixels(self: RenderTarget) usize {
        return @divExact(@as(usize, @intCast(self.canvas.value.pitch)), @sizeOf(u32));
    }

    /// Raw write, no alpha blending
    pub fn setPixel(self: RenderTarget, x: i32, y: i32, color: u32) void {
        if (x < 0 or y < 0) return;
        if (x >= @as(i32, @intCast(self.size_x)) or y >= @as(i32, @intCast(self.size_y))) return;

        const idx = @as(usize, @intCast(y)) * self.pitchPixels() + @as(usize, @intCast(x));
        const pixels = self.getPixels();
        if (idx >= pixels.len) return;
        pixels[idx] = color;
    }

    /// Alpha blended write
    pub fn blendPixel(self: RenderTarget, x: i32, y: i32, color: u32) void {
        if (x < 0 or y < 0) return;
        if (x >= @as(i32, @intCast(self.size_x)) or y >= @as(i32, @intCast(self.size_y))) return;

        const a = (color >> 24) & 0xFF;
        const r_src = (color >> 16) & 0xFF;
        const g_src = (color >> 8) & 0xFF;
        const b_src = color & 0xFF;

        const pixels = self.getPixels();
        const idx = @as(usize, @intCast(y)) * self.pitchPixels() + @as(usize, @intCast(x));
        if (idx >= pixels.len) return;

        const dst = pixels[idx];
        const r_dst = (dst >> 16) & 0xFF;
        const g_dst = (dst >> 8) & 0xFF;
        const b_dst = dst & 0xFF;

        const out_r = (r_src * a + r_dst * (255 - a)) / 255;
        const out_g = (g_src * a + g_dst * (255 - a)) / 255;
        const out_b = (b_src * a + b_dst * (255 - a)) / 255;

        const out_a = if (self.opaque_bg) @as(u32, 0xFF) else blk: {
            const a_dst = (dst >> 24) & 0xFF;
            break :blk a + a_dst * (255 - a) / 255;
        };

        pixels[idx] = (out_a << 24) | (out_r << 16) | (out_g << 8) | out_b;
    }
};
