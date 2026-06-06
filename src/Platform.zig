// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const sdl = @import("zsdl2");
const types = @import("types.zig");

pub const Vec2_cint = struct { x: c_int, y: c_int };
pub const WindowPosition = union(enum) {
    centered: void,
    xy: Vec2_cint,
};

pub const Platform = struct {
    pub fn init() !Platform {
        // we don't use opengl but this prevents weird frame
        // stutters on ProMotion displays for some reason?
        try sdl.setHint("SDL_RENDERER_DRIVER", "opengl");
        try sdl.init(.{ .video = true });

        return .{

        };
    }

    pub fn createWindow(_: Platform, name: [*:0]const u8, position: WindowPosition, size: types.Vec2_u16) !*sdl.Window {
        const p: Vec2_cint = switch (position) {
            .centered => .{ .x = sdl.Window.pos_centered, .y = sdl.Window.pos_centered },
            .xy => |xy| xy
        };

        return try sdl.createWindow(name, p.x, p.y, size.x, size.y, .{ .resizable = true });
    }

    pub fn deinit(_: Platform) void {
        sdl.quit();
    }
};
