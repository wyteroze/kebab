// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const Vec3 = @import("Vec3.zig").Vec3;
const input = @import("../../input/Input.zig");
const InputCode = input.InputCode;
const InputValue = input.InputValue;

pub const InputEvent = struct {
    pub const hidden = .{ "code", "value", "delta" };
    pub const name = "InputEvent";
    code: InputCode,
    value: InputValue,
    delta: Vec3,

    pub fn getCode(self: InputEvent) [:0]const u8 { return self.code.name(); }
    pub fn getDelta(self: InputEvent) Vec3 { return self.delta; }
    pub fn getValue(self: InputEvent) f32 { return switch (self.value) { .scalar => |s| s, .vec2 => 0 }; }
};
