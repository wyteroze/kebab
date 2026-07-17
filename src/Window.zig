// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const Diagnostic = @import("script/shared.zig").Diagnostic;
const WidgetRegistry = @import("WidgetRegistry.zig").WidgetRegistry;
const WindowManager = @import("WindowManager.zig").WindowManager;
const RenderTarget = @import("render/RenderTarget.zig").RenderTarget;
const Vec2 = @import("script/objects/Vec2.zig").Vec2;
const Anchor = @import("ui/Widget.zig").Anchor;
const Widget = @import("ui/Widget.zig").Widget;
const Handle = @import("script/reflect/marshal.zig").Handle;
const Color = @import("Color.zig").Color;
const Callback = @import("script/shared.zig").Callback;
const Scene = @import("Scene.zig").Scene;
const Object = @import("object.zig").Object;

const input = @import("input/Input.zig");
const InputState = input.InputState;
const InputCode = input.InputCode;

pub const WindowUI = struct {
    pub const lua_ref = true;
    pub const hidden = .{ "window" };
    window: *Window = undefined,

    pub fn Panel(self: *WindowUI, anchor: Anchor, offset: Vec2, size: Vec2) !Handle(Widget) {
        const window = self.window;

        const widget = try window.allocator.create(Widget);
        errdefer window.allocator.destroy(widget);

        widget.* = .{
            .allocator = window.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = size.vec,
            .data = .{ .panel = .{ .bg = Color.fromARGB(255, 255, 255, 255) } },
        };

        try window.registry.addWidget(widget);
        return .{ .ptr = widget };
    }

    pub fn Label(self: *WindowUI, anchor: Anchor, offset: Vec2, text: []const u8) !Handle(Widget) {
        const window = self.window;

        const owned = try window.allocator.dupe(u8, text);
        errdefer window.allocator.free(owned);

        const widget = try window.allocator.create(Widget);
        errdefer window.allocator.destroy(widget);

        widget.* = .{
            .allocator = window.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = .{ 0, 0 }, // updated at draw time to reflect the size of the text
            .data = .{ .label = .{ .content = .{ .text = owned, .color = Color.fromARGB(255, 255, 255, 255) } } },
        };

        try window.registry.addWidget(widget);
        return .{ .ptr = widget };
    }

    pub fn Button(self: *WindowUI, anchor: Anchor, offset: Vec2, size: Vec2, text: []const u8) !Handle(Widget) {
        const window = self.window;

        const owned = try window.allocator.dupe(u8, text);
        errdefer window.allocator.free(owned);

        const widget = try window.allocator.create(Widget);
        errdefer window.allocator.destroy(widget);

        widget.* = .{
            .allocator = window.allocator,
            .anchor = anchor,
            .offset = offset.vec,
            .size = size.vec,
            .data = .{ .button = .{
                .bg = Color.fromARGB(255, 128, 128, 128),
                .state = .normal,
                .content = .{ .text = owned, .color = Color.fromARGB(255, 255, 255, 255) }
            } },
        };

        try self.window.registry.addWidget(widget);
        return .{ .ptr = widget };
    }
};

pub const WindowInput = struct {
    pub const lua_ref = true;
    pub const hidden = .{ "window", "bind" };
    window: *Window = undefined,

    fn bind(self: *WindowInput, phase: anytype, code: InputCode, cb: Callback) !void {
        const state = &self.window.input;
        try state.bindings.append(state.allocator, .{ .phase = phase, .code = code, .cb = cb });
    }
    pub fn OnBegin(self: *WindowInput, code: InputCode, cb: Callback) !void { try self.bind(.begin, code, cb); }
    pub fn OnEnd(self: *WindowInput, code: InputCode, cb: Callback) !void { try self.bind(.end, code, cb); }
    pub fn OnChange(self: *WindowInput, code: InputCode, cb: Callback) !void { try self.bind(.change, code, cb); }

    pub fn IsDown(self: *WindowInput, code: InputCode) bool { return self.window.input.down.contains(code); }
    pub fn GetValue(self: *WindowInput, code: InputCode) f32 {
        return if (self.window.input.down.get(code)) |v| switch (v) { .scalar => |s| s, .vec2 => 0 } else 0;
    }

    pub fn setMouseVisible(_: *WindowInput, visible: bool) !void {
        if (visible) try sdl3.mouse.show() else try sdl3.mouse.hide();
    }
    pub fn getMouseVisible(_: WindowInput) bool {
        return sdl3.mouse.visible();
    }

    pub fn setMouseLocked(self: *WindowInput, locked: bool) !void {
        try sdl3.mouse.setWindowRelativeMode(self.window.handle, locked);
    }
    pub fn getMouseLocked(self: WindowInput) bool {
        return sdl3.mouse.getWindowRelativeMode(self.window.handle);
    }
};

pub const Window = struct {
    pub const lua_ref = true;
    pub const lua_name = "WindowInstance";
    pub const hidden = .{ "handle", "id", "target", "registry", "manager", "input", "update", "scene", "camera", "callbacks" };
    diagnostic: Diagnostic = .{},
    allocator: std.mem.Allocator,

    handle: sdl3.video.Window,
    id: sdl3.video.WindowId,
    target: RenderTarget,
    registry: WidgetRegistry,
    manager: *WindowManager,
    input: InputState,

    UI: WindowUI = .{},
    Input: WindowInput = .{},

    scene: ?*Scene = null,
    camera: ?*Object = null,
    callbacks: std.ArrayList(Callback),

    pub fn getTitle(self: Window) ?[:0]const u8 { return self.handle.getTitle(); }
    pub fn setTitle(self: *Window, title: [:0]const u8) !void { try self.handle.setTitle(title); }

    pub fn getScene(self: Window) ?Handle(Scene) {
        return .{ .ptr = self.scene orelse return null };
    }
    pub fn setScene(self: *Window, scene: ?Handle(Scene)) void {
        self.scene = if (scene) |s| s.ptr else null;
    }

    pub fn getCamera(self: Window) ?Handle(Object) {
        return .{ .ptr = self.camera orelse return null };
    }

    pub fn setCamera(self: *Window, camera: Handle(Object)) !void {
        switch (camera.ptr.data) {
            .camera => self.camera = camera.ptr,
            else => |d| { self.diagnostic.set("expected camera, got {s}", .{d.luaName()}); return error.ExpectedCamera; },
        }
    }

    pub fn update(self: *Window, dt: f32) void {
        for (self.callbacks.items) |cb| {
            cb.call(.{ dt });
        }
    }

    pub fn Close(self: *Window) void {
        self.manager.close(self);
    }

    pub fn OnUpdate(self: *Window, cb: Callback) !void {
        try self.callbacks.append(self.allocator, cb);
    }

    pub fn deinit(self: *Window) void {
        for (self.callbacks.items) |cb| cb.deinit();
        self.callbacks.deinit(self.allocator);
        self.input.deinit();
        self.registry.deinit();
        self.target.deinit();
        self.handle.deinit();
    }
};
