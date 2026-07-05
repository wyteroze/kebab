// Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.

const std = @import("std");
const zlua = @import("zlua");
const sdl3 = @import("sdl3");
const shared = @import("shared.zig");
const types = @import("../types.zig");
const lua_vec = @import("lua_vec.zig");
const Platform = @import("../Platform.zig").Platform;
const log = @import("../log.zig").lua;
const Lua = zlua.Lua;
const Vec2_SIMD = types.Vec2_SIMD;

pub const InputCode = enum {
    A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
    Exclamation, At, Hashtag, Dollar, Percent, Caret, Ampersand, Asterisk, LeftParen, RightParen,
    Plus, Minus, Underscore, Equal,
    LeftBrace, RightBrace, LeftBracket, RightBracket, Pipe, Slash, Backslash, Colon, Semicolon, Quote, DoubleQuote,
    Comma, Period, LessThan, GreaterThan, Question, Tilde, Backquote,
    Escape, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, Tab, Backspace, CapsLock, Enter,
    LeftShift, RightShift, LeftControl, RightControl, LeftAlt, RightAlt, LeftSuper, RightSuper,
    Up, Down, Left, Right,
    LeftMouseButton, RightMouseButton, MiddleMouseButton, MouseScroll, MouseMove, Space,

    pub fn name(self: InputCode) [:0]const u8 {
        return switch (self) {
            .A => "A", .B => "B", .C => "C", .D => "D", .E => "E", .F => "F", .G => "G", .H => "H",
            .I => "I", .J => "J", .K => "K", .L => "L", .M => "M", .N => "N", .O => "O", .P => "P",
            .Q => "Q", .R => "R", .S => "S", .T => "T", .U => "U", .V => "V", .W => "W", .X => "X",
            .Y => "Y", .Z => "Z",
            .Exclamation => "Exclamation", .At => "At", .Hashtag => "Hashtag", .Dollar => "Dollar",
            .Percent => "Percent", .Caret => "Caret", .Ampersand => "Ampersand", .Asterisk => "Asterisk",
            .LeftParen => "LeftParen", .RightParen => "RightParen", .Plus => "Plus", .Minus => "Minus",
            .Underscore => "Underscore", .Equal => "Equal",
            .LeftBrace => "LeftBrace", .RightBrace => "RightBrace", .LeftBracket => "LeftBracket",
            .RightBracket => "RightBracket", .Pipe => "Pipe", .Slash => "Slash", .Backslash => "Backslash",
            .Colon => "Colon", .Semicolon => "Semicolon", .Quote => "Quote", .DoubleQuote => "DoubleQuote",
            .Comma => "Comma", .Period => "Period", .LessThan => "LessThan", .GreaterThan => "GreaterThan",
            .Question => "Question", .Tilde => "Tilde", .Backquote => "Backquote",
            .Escape => "Escape", .F1 => "F1", .F2 => "F2", .F3 => "F3", .F4 => "F4", .F5 => "F5",
            .F6 => "F6", .F7 => "F7", .F8 => "F8", .F9 => "F9", .F10 => "F10", .F11 => "F11", .F12 => "F12",
            .Tab => "Tab", .Backspace => "Backspace", .CapsLock => "CapsLock", .Enter => "Enter",
            .LeftShift => "LeftShift", .RightShift => "RightShift", .LeftControl => "LeftControl",
            .RightControl => "RightControl", .LeftAlt => "LeftAlt", .RightAlt => "RightAlt",
            .LeftSuper => "LeftSuper", .RightSuper => "RightSuper",
            .Up => "Up", .Down => "Down", .Left => "Left", .Right => "Right",
            .LeftMouseButton => "LeftMouseButton", .RightMouseButton => "RightMouseButton",
            .MiddleMouseButton => "MiddleMouseButton", .MouseScroll => "MouseScroll", .MouseMove => "MouseMove",
            .Space => "Space"
        };
    }

    pub fn fromString(s: []const u8) ?InputCode {
        return code_map.get(s);
    }
};

const code_map = std.StaticStringMap(InputCode).initComptime(blk: {
    const fields = std.meta.fields(InputCode);
    var entries: [fields.len]struct { []const u8, InputCode } = undefined;
    for (fields, 0..) |f, i| {
        entries[i] = .{ f.name, @field(InputCode, f.name) };
    }

    break :blk entries;
});

pub fn fromSdlKeyCode(sc: ?sdl3.keycode.Keycode) ?InputCode {
    if (sc == null) return null;

    return switch (sc.?) {
        .a => .A, .b => .B, .c => .C, .d => .D, .e => .E, .f => .F, .g => .G, .h => .H,
        .i => .I, .j => .J, .k => .K, .l => .L, .m => .M, .n => .N, .o => .O, .p => .P,
        .q => .Q, .r => .R, .s => .S, .t => .T, .u => .U, .v => .V, .w => .W, .x => .X,
        .y => .Y, .z => .Z,
        .escape => .Escape,
        .func1 => .F1, .func2 => .F2, .func3 => .F3, .func4 => .F4, .func5 => .F5, .func6 => .F6,
        .func7 => .F7, .func8 => .F8, .func9 => .F9, .func10 => .F10, .func11 => .F11, .func12 => .F12,
        .tab => .Tab, .backspace => .Backspace, .caps_lock => .CapsLock, .return_key => .Enter,
        .left_shift => .LeftShift, .right_shift => .RightShift,
        .left_ctrl => .LeftControl, .right_ctrl => .RightControl,
        .left_alt => .LeftAlt, .right_alt => .RightAlt,
        .left_gui => .LeftSuper, .right_gui => .RightSuper,
        .up => .Up, .down => .Down, .left => .Left, .right => .Right,
        .comma => .Comma, .period => .Period, .semicolon => .Semicolon, .apostrophe => .Quote,
        .left_bracket => .LeftBracket, .right_bracket => .RightBracket,
        .backslash => .Backslash, .slash => .Slash, .grave => .Backquote,
        .minus => .Minus, .equals => .Equal, .space => .Space,
        .pipe => .Pipe, .tilde => .Tilde, .exclaim => .Exclamation, .at => .At, .hash => .Hashtag,
        .dollar => .Dollar, .percent => .Percent, .caret => .Caret, .ampersand => .Ampersand,
        .asterisk => .Asterisk, .left_paren => .LeftParen, .right_paren => .RightParen,
        .underscore => .Underscore, .plus => .Plus, .left_brace => .LeftBrace, .right_brace => .RightBrace,
        .colon => .Colon, .dblapostrophe => .DoubleQuote, .greater => .GreaterThan, .less => .LessThan,
        .question => .Question,
        else => null,
    };
}

pub fn fromMouseButton(button: sdl3.mouse.Button) ?InputCode {
    return switch (button) {
        .left => .LeftMouseButton,
        .right => .RightMouseButton,
        .middle => .MiddleMouseButton,
        else => null,
    };
}

pub const InputValue = union(enum) {
    scalar: f32,
    vec2: Vec2_SIMD
};

const CallbackKind = enum { begin, change, end };

const Callback = struct {
    lua: *Lua,
    ref: i32,
    code_filter: ?InputCode, // null means it listens to all codes
    kind: CallbackKind,
    disconnected: bool = false
};

var allocator: std.mem.Allocator = undefined;
var callbacks: std.ArrayList(*Callback) = undefined;
var down_state: std.AutoHashMap(InputCode, InputValue) = undefined;
var window: sdl3.video.Window = undefined;

pub fn pushInputTable(l: *Lua, code: InputCode, value: InputValue, delta: InputValue, user_index: i32) void {
    l.newTable();

    _ = l.pushString(code.name());
    l.setField(-2, "Code");

    switch (value) {
        .scalar => |s| l.pushNumber(s),
        .vec2 => |v| lua_vec.pushVec2(l, v)
    }
    l.setField(-2, "Value");

    switch (delta) {
        .scalar => |s| l.pushNumber(s),
        .vec2 => |v| lua_vec.pushVec2(l, v)
    }
    l.setField(-2, "Delta");

    l.pushInteger(user_index);
    l.setField(-2, "UserIndex");
}

fn dispatch(kind: CallbackKind, code: InputCode, value: InputValue, delta: InputValue, user_index: i32) void {
    for (callbacks.items) |cb| {
        if (cb.disconnected) continue;
        if (cb.kind != kind) continue;
        if (cb.code_filter) |f| {
            if (f != code) continue;
        }

        const l = cb.lua;
        _ = l.getIndexRaw(zlua.registry_index, cb.ref);

        pushInputTable(l, code, value, delta, user_index);
        l.protectedCall(.{ .args = 1, .results = 0 }) catch {
            log.err("Input callback error: {s}", .{ l.toString(-1) catch "???" });
            l.pop(1);
        };
    }
}

pub fn fireBegin(code: InputCode, value: InputValue, user_index: i32) void {
    down_state.put(code, value) catch {};
    dispatch(.begin, code, value, .{ .scalar = 0 }, user_index);
}

pub fn fireEnd(code: InputCode, user_index: i32) void {
    _ = down_state.remove(code);
    dispatch(.end, code, .{ .scalar = 0 }, .{ .scalar = 0 }, user_index);
}

pub fn fireChange(code: InputCode, value: InputValue, delta: InputValue, user_index: i32) void {
    down_state.put(code, value) catch {};
    dispatch(.change, code, value, delta, user_index);
}

fn registerCallback(l: *Lua, kind: CallbackKind, code_filter: ?InputCode, fn_stack_idx: i32) i32 {
    l.checkType(fn_stack_idx, .function);
    l.pushValue(fn_stack_idx);
    const ref = l.ref(zlua.registry_index);

    const cb = allocator.create(Callback) catch {
        l.raiseErrorStr("out of memory registering input callback", .{});
        return 0;
    };
    cb.* = .{ .lua = l, .ref = ref, .code_filter = code_filter, .kind = kind };

    callbacks.append(allocator, cb) catch {
        l.unref(zlua.registry_index, ref);
        allocator.destroy(cb);
        l.raiseErrorStr("out of memory registering input callback", .{});
        return 0;
    };

    l.pushLightUserdata(cb);
    l.pushClosure(zlua.wrap(disconnectCallback), 1);
    return 1;
}

fn disconnectCallback(l: *Lua) i32 {
    const cb = @as(*Callback, @ptrCast(@alignCast(
        l.toUserdata(anyopaque, Lua.upvalueIndex(1)) catch unreachable
    )));

    if (!cb.disconnected) {
        cb.disconnected = true;
        l.unref(zlua.registry_index, cb.ref);
    }

    return 0;
}

fn parseCodeArg(l: *Lua, index: i32) ?InputCode {
    const s = l.checkString(index);
    const code = InputCode.fromString(s);
    if (code == null) {
        l.raiseErrorStr("invalid input code '%s'", .{ s.ptr });
    }

    return code;
}

fn inputOnBegin(l: *Lua) i32 {
    if (l.typeOf(1) == .string) {
        const code = parseCodeArg(l, 1) orelse return 0;
        return registerCallback(l, .begin, code, 2);
    }

    return registerCallback(l, .begin, null, 1);
}

fn inputOnEnd(l: *Lua) i32 {
    if (l.typeOf(1) == .string) {
        const code = parseCodeArg(l, 1) orelse return 0;
        return registerCallback(l, .end, code, 2);
    }

    return registerCallback(l, .end, null, 1);
}

fn inputOnChange(l: *Lua) i32 {
    if (l.typeOf(1) == .string) {
        const code = parseCodeArg(l, 1) orelse return 0;
        return registerCallback(l, .change, code, 2);
    }

    return registerCallback(l, .change, null, 1);
}

fn inputIsDown(l: *Lua) i32 {
    const code = parseCodeArg(l, 1) orelse return 0;
    l.pushBoolean(down_state.contains(code));

    return 1;
}

fn inputGetValue(l: *Lua) i32 {
    const code = parseCodeArg(l, 1) orelse return 0;
    if (down_state.get(code)) |v| {
        switch (v) {
            .scalar => |s| l.pushNumber(s),
            .vec2 => |vec| lua_vec.pushVec2(l, vec)
        }
    } else {
        l.pushNumber(0);
    }

    return 1;
}

fn inputIndex(l: *Lua) i32 {
    const key = l.checkString(2);

    // TODO: move to sdl3, better zig bindings and software rendering
    // performance plus we won't need to deal with this type of stuff
    if (std.mem.eql(u8, key, "MouseLocked")) {
        log.warn("Input.MouseLocked always returns false due to SDL issues", .{});

        l.pushBoolean(false);
        return 1;
    } else if (std.mem.eql(u8, key, "MouseVisible")) {
        log.warn("Input.MouseVisible always returns false due to SDL issues", .{});

        l.pushBoolean(false);
        return 1;
    }

    l.raiseErrorStr("no property named '%s' exists", .{ key.ptr });
    return 0;
}

fn inputNewIndex(l: *Lua) i32 {
    const key = l.checkString(2);
    if (std.mem.eql(u8, key, "MouseLocked")) {
        const locked = l.toBoolean(3);
        sdl3.mouse.setWindowRelativeMode(window, locked) catch {
            l.raiseErrorStr("failed to set mouse lock to '%s'", .{ locked });
            return 0;
        };

        return 0;
    } else if (std.mem.eql(u8, key, "MouseVisible")) {
        const visible = l.toBoolean(3);
        if (visible) {
            sdl3.mouse.show() catch {
                l.raiseErrorStr("failed to show mouse cursor", .{});
                return 0;
            };
        } else {
            sdl3.mouse.hide() catch {
                l.raiseErrorStr("failed to hide mouse cursor", .{});
                return 0;
            };
        }

        return 0;
    }

    l.raiseErrorStr("no property named '%s' exists, you can not assign to it", .{ key.ptr });
    return 0;
}

const input_lib = [_]zlua.FnReg{
    .{ .name = "OnBegin", .func = zlua.wrap(inputOnBegin) },
    .{ .name = "OnEnd", .func = zlua.wrap(inputOnEnd) },
    .{ .name = "OnChange", .func = zlua.wrap(inputOnChange) },
    .{ .name = "IsDown", .func = zlua.wrap(inputIsDown) },
    .{ .name = "GetValue", .func = zlua.wrap(inputGetValue) },
};

pub fn register(l: *Lua, a: std.mem.Allocator, w: sdl3.video.Window) !void {
    window = w;
    allocator = a;
    callbacks = std.ArrayList(*Callback).empty;
    down_state = std.AutoHashMap(InputCode, InputValue).init(allocator);

    l.newTable();
    l.setFuncs(&input_lib, 0);

    l.newTable();
    l.pushFunction(zlua.wrap(inputIndex));
    l.setField(-2, "__index");
    l.pushFunction(zlua.wrap(inputNewIndex));
    l.setField(-2, "__newindex");
    l.setMetatable(-2);

    l.setGlobal("Input");
}

pub fn deinit(l: *Lua) void {
    for (callbacks.items) |cb| {
        if (!cb.disconnected) l.unref(zlua.registry_index, cb.ref);
        allocator.destroy(cb);
    }

    callbacks.deinit(allocator);
    down_state.deinit();
}
