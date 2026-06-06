// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl = @import("zsdl2");

const types     = @import("types.zig");
const Platform  = @import("Platform.zig").Platform;
const Renderer  = @import("Renderer.zig").Renderer;
const Mesh      = @import("Mesh.zig").Mesh;
const Camera    = @import("Camera.zig").Camera;
const Instance  = @import("Instance.zig").Instance;

const fps = 120;
const fps_ms = 1000 / fps;
const width = 384;
const height = 360;

fn isPressed(state: []const u8, scancode: sdl.Scancode) bool {
    return state[@intFromEnum(scancode)] != 0;
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var platform = try Platform.init();
    defer platform.deinit();

    var window = try platform.createWindow("kebab", .centered, .{ .x = width*2, .y = height*2 });
    defer window.destroy();

    var camera = Camera.init(0.1, 1000.0, 90.0, @as(f32, @floatFromInt(height)) / @as(f32, @floatFromInt(width)));
    var renderer = try Renderer.init(allocator, window, .{ .x = width, .y = height }, &camera, true);
    defer renderer.deinit();

    var cubeMesh = try Mesh.loadFromFile(allocator, io, "src/assets/models/utah_teapot_10x.obj");
    defer cubeMesh.deinit();

    var cube = Instance{
        .mesh = &cubeMesh,
        .transform = types.Transform.identity()
    };

    cube.transform.position[2] += 5.0;

    var running = true;
    var lastTimeMs: u64 = sdl.getPerformanceCounter();
    const frequency = @as(f32, @floatFromInt(sdl.getPerformanceFrequency()));

    while (running) {
        const currentTime = sdl.getPerformanceCounter();
        const dt = @as(f32, @floatFromInt(currentTime - lastTimeMs)) / frequency;
        lastTimeMs = currentTime;

        // events
        var event: sdl.Event = undefined;
        while (sdl.pollEvent(&event)) {
            if (event.type == .quit) {
                running = false;
            } else if (event.type == .mousemotion) {
                camera.transform.rotation[0] += @as(f32, @floatFromInt(event.motion.yrel));
                camera.transform.rotation[1] += @as(f32, @floatFromInt(event.motion.xrel));
            }
        }

        const state = sdl.getKeyboardState();
        const factor = 2;

        if (isPressed(state, .w))      camera.transform.position[2] += dt * factor;
        if (isPressed(state, .s))      camera.transform.position[2] -= dt * factor;
        if (isPressed(state, .a))      camera.transform.position[0] -= dt * factor;
        if (isPressed(state, .d))      camera.transform.position[0] += dt * factor;
        if (isPressed(state, .space))  camera.transform.position[1] += dt * factor;
        if (isPressed(state, .lshift)) camera.transform.position[1] -= dt * factor;

        // object updates
        //cube.transform.rotation += types.Vec3_SIMD{ dt * 45, 0, dt * 45 };

        // rendering
        renderer.drawBackground();
        try renderer.drawMesh(cube.mesh, &cube.transform);
        renderer.visualizeAxes();

        try renderer.present();
    }
}
