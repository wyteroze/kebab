// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const sdl3 = @import("sdl3");
const zlua = @import("zlua");
const Lua = zlua.Lua;

const log = @import("../log.zig").script;
const libs = @import("libs/libs.zig");
const reflect = @import("reflect/reflect.zig");

const SceneRegistry = @import("../SceneRegistry.zig").SceneRegistry;

pub const ScriptEngine = struct {
    lua: *Lua,

    pub fn init(allocator: std.mem.Allocator, io: std.Io, sceneRegistry: *SceneRegistry, window: sdl3.video.Window) !ScriptEngine {
        var lua = try Lua.init(allocator);
        lua.openLibs();

        _ = io;
        _ = sceneRegistry;
        _ = window;
        //try reflect.registerAll(lua, libs, .{ allocator, io, sceneRegistry, window });

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

    pub fn deinit(self: *ScriptEngine) void {
        self.lua.deinit();
    }
};
