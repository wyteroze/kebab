// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const zlua = @import("zlua");

const types         = @import("types.zig");
const log           = @import("log.zig").engine;
const Platform      = @import("Platform.zig").Platform;
const Renderer      = @import("Renderer.zig").Renderer;
const Mesh          = @import("Mesh.zig").Mesh;
const Sprite        = @import("Sprite.zig").Sprite;
const Camera        = @import("Camera.zig").Camera;
const Object        = @import("object.zig").Object;
const ScriptEngine  = @import("script/ScriptEngine.zig").ScriptEngine;
const SceneRegistry = @import("SceneRegistry.zig").SceneRegistry;
const scene = @import("Scene.zig");
const lua_input = @import("script/lua_input.zig");

const fps = 120;
const fps_ms = 1000 / fps;
const width = 384;
const height = 360;

// You can customize this to filter what types of logs
// are actually seen in the output
pub const std_options: std.Options = .{
    // Default log level
    .log_level = .debug,

    // Filters for scopes
    .log_scope_levels = &.{
        .{ .scope = .script, .level = .debug },
        .{ .scope = .render, .level = .debug },
        .{ .scope = .parse, .level = .debug },
        .{ .scope = .engine, .level = .debug }
    }
};

fn isPressed(state: []const u8, scancode: sdl3.Scancode) bool {
    return state[@intFromEnum(scancode)] != 0;
}

pub fn main(init: std.process.Init) !void {
    log.info("Initializing...", .{});
    const allocator = init.gpa;
    const io = init.io;

    scene.skybox_mesh = try Mesh.loadFromFile(allocator, io, "src/assets/models/skybox.obj");

    var platform = try Platform.init();
    defer platform.deinit();

    var window = try platform.createWindow("kebab", .{ .centered = null }, .{ .centered = null }, .{ .x = width*2, .y = height*2 });
    defer window.deinit();

    var renderer = try Renderer.init(allocator, window, .{ .x = width, .y = height });
    defer renderer.deinit();

    var sceneRegistry = SceneRegistry.init(allocator);
    var scriptEngine = try ScriptEngine.init(allocator, io, &sceneRegistry, window);
    defer sceneRegistry.deinit();
    defer scriptEngine.deinit();

    scriptEngine.runFile("src/assets/scripts/main.lua");
    log.info("Initialized", .{});

    var running = true;
    var lastTimeMs: u64 = sdl3.timer.getPerformanceCounter();
    const frequency = @as(f32, @floatFromInt(sdl3.timer.getPerformanceFrequency()));

    log.info("Starting loop", .{});
    while (running) {
        const currentTime = sdl3.timer.getPerformanceCounter();
        const dt = @as(f32, @floatFromInt(currentTime - lastTimeMs)) / frequency;
        lastTimeMs = currentTime;

        // events
        while (sdl3.events.poll()) |e| {
            switch (e) {
                .quit => running = false,

                else => scriptEngine.handleInput(e)
            }
        }

        // rendering
        renderer.drawBackground();

        const current_scene = sceneRegistry.current_scene;
        if (current_scene) |s| {
            s.update(dt);
            try renderer.drawScene(s);
        }

        try renderer.present();
    }
}
