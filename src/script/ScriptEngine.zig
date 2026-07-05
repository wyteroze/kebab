// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const zlua = @import("zlua");
const Lua = zlua.Lua;

const log = @import("../log.zig").script;
const lua_vec = @import("lua_vec.zig");
const lua_log = @import("lua_log.zig");
const lua_scene = @import("lua_scene.zig");
const lua_object = @import("lua_object.zig");
const lua_assets = @import("lua_assets.zig");
const lua_input = @import("lua_input.zig");

const SceneRegistry = @import("../SceneRegistry.zig").SceneRegistry;

pub const ScriptEngine = struct {
    lua: *Lua,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, sceneRegistry: *SceneRegistry, window: sdl3.video.Window) !ScriptEngine {
        var lua = try Lua.init(allocator);
        lua.openLibs();

        try lua_vec.register(lua);
        try lua_log.register(lua, allocator);
        try lua_scene.register(lua, allocator, sceneRegistry);
        try lua_object.register(lua, allocator);
        try lua_assets.register(lua, allocator, io);
        try lua_input.register(lua, allocator, window);

        return .{
            .lua = lua
        };
    }

    // Runs a script from the given path. Handles all errors
    pub fn runFile(self: *ScriptEngine, file: [:0]const u8) void {
        log.info("loading script '{s}'", .{file});

        self.lua.doFile(file) catch {
            const msg = self.lua.toString(-1) catch "unknown error";
            var formatted = false;

            // find the ": "
            if (std.mem.indexOf(u8, msg, ": ")) |msg_sep| {
                // search backwards in order to find the separator of file and line
                if (std.mem.findScalarLast(u8, msg[0..msg_sep], ':')) |line_sep| {
                    const filename = msg[0..line_sep];
                    const line = msg[line_sep+1 .. msg_sep];
                    const err_msg = msg[msg_sep + 2 ..]; // skip ":"

                    log.err("{s}\n    in {s} (line {s})", .{ err_msg, filename, line });
                    formatted = true;
                }
            }

            if (!formatted) {
                log.err("{s}", .{ msg });
            }

            self.lua.pop(1);
        };
    }

    pub fn fireInputBegin(
        _: *ScriptEngine,
        code: lua_input.InputCode,
        value: lua_input.InputValue,
        user_index: i32
    ) void {
        lua_input.fireBegin(code, value, user_index);
    }

    pub fn fireInputEnd(
        _: *ScriptEngine,
        code: lua_input.InputCode,
        user_index: i32
    ) void {
        lua_input.fireEnd(code, user_index);
    }

    pub fn fireInputChange(
        _: *ScriptEngine,
        code: lua_input.InputCode,
        value: lua_input.InputValue,
        delta: lua_input.InputValue,
        user_index: i32
    ) void {
        lua_input.fireChange(code, value, delta, user_index);
    }

    pub fn handleInput(_: *ScriptEngine, event: sdl3.events.Event) void {
        switch (event) {
            .key_down => |k| if (!k.repeat) {
                if (lua_input.fromSdlKeyCode(k.key)) |code| {
                    lua_input.fireBegin(code, .{ .scalar = 1 }, 1);
                }
            },
            .key_up => |k| {
                if (lua_input.fromSdlKeyCode(k.key)) |code| {
                    lua_input.fireEnd(code, 1);
                }
            },
            .mouse_button_down => |m| {
                if (lua_input.fromMouseButton(m.button)) |code| {
                    lua_input.fireBegin(code, .{ .scalar = 1 }, 1);
                }
            },
            .mouse_button_up => |m| {
                if (lua_input.fromMouseButton(m.button)) |code| {
                    lua_input.fireEnd(code, 1);
                }
            },
            .mouse_motion => |m| {
                lua_input.fireChange(
                    .MouseMove,
                    .{ .vec2 = .{ m.x, m.y } },
                    .{ .vec2 = .{ m.x_rel, m.y_rel } },
                    1,
                );
            },
            .mouse_wheel => |m| {
                lua_input.fireChange(
                    .MouseScroll,
                    .{ .vec2 = .{ m.scroll_x, m.scroll_y } },
                    .{ .vec2 = .{ m.scroll_x, m.scroll_y } },
                    1,
                );
            },

            else => {}
        }
    }

    pub fn deinit(self: *ScriptEngine) void {
        lua_input.deinit(self.lua);
        self.lua.deinit();
    }
};
