// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const Diagnostic = @import("../shared.zig").Diagnostic;
const Color = @import("../../Color.zig").Color;
const ColorRegistry = @import("../../ColorRegistry.zig").ColorRegistry;

pub const ColorLib = struct {
    pub const hidden = .{ "registry" };
    pub const name = "Color";
    diagnostic: Diagnostic = .{},
    registry: *ColorRegistry,

    pub fn init(colorRegistry: *ColorRegistry) !ColorLib {
        return .{
            .registry = colorRegistry
        };
    }

    pub fn fromName(self: *ColorLib, colorName: []const u8, alpha: ?u8) !Color {
        return self.registry.named(colorName, alpha orelse 255) orelse {
            self.diagnostic.set("no color named '{s}'", .{colorName});
            return error.UnknownColor;
        };
    }

    pub fn fromARGB(_: *ColorLib, a: u8, r: u8, g: u8, b: u8) Color {
        return .{ .color = (@as(u32, a) << 24) | (@as(u32, r) << 16) | (@as(u32, g) << 8) | b };
    }

    pub fn fromHex(self: *ColorLib, hexCode: []const u8) !Color {
        var hex = hexCode;
        if (hex.len >= 2 and hex[0] == '0' and (hex[1] == 'x' or hex[1] == 'X')) hex = hex[2..];

        return .{ .color = std.fmt.parseInt(u32, hex, 16) catch {
            self.diagnostic.set("invalid hex code '{s}', expected AARRGGBB", .{hexCode});
            return error.InvalidHex;
        } };
    }
};
