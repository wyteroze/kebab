--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta Input
-- This file is for the Lua Language Server, do not require it

--- @alias InputCode "A" | "B" | "C" | "D" | "E" | "F" |"G" | "H" | "I" | "J" | "K" | "L" | "M" | "N" | "O" | "P" | "Q" | "R" | "S" | "T" | "U" | "V" | "W" | "X" | "Y" | "Z" | "Exclamation" | "At" | "Hashtag" | "Dollar" | "Percent" | "Caret" | "Ampersand" | "Asterisk" | "LeftParen" | "RightParen" | "Plus" | "Minus" | "Underscore" | "Equal" | "LeftBrace" | "RightBrace" | "LeftBracket" | "RightBracket" | "Pipe" | "Slash" | "Backslash" | "Colon" | "Semicolon" | "Quote" | "DoubleQuote" | "Comma" | "Period" | "LessThan" | "GreaterThan" | "Question" | "Tilde" | "Backquote" | "Escape" | "F1" | "F2" | "F3" | "F4" | "F5" | "F6" | "F7" | "F8" | "F9" | "F10" | "F11" | "F12" | "Tab" | "Backspace" | "CapsLock" | "Enter" | "LeftShift" | "RightShift" | "LeftControl" | "RightControl" | "LeftAlt" | "RightAlt" | "LeftSuper" | "RightSuper" | "Up" | "Down" | "Left" | "Right" | "LeftMouseButton" | "RightMouseButton" | "MiddleMouseButton" | "MouseScroll" | "MouseMove" | "Space"

--- Represents a single input event, passed to the callbacks registered with
--- window:OnBegin / window:OnEnd / window:OnChange.
--- @class Input
---
--- The input code as a string.
--- @field Code InputCode
---
--- The input's value.
--- For keys and other digital inputs (on or off), this is either 0 or 1.
--- For analog inputs, this ranges from 0-1.
--- @field Value number|Vec2
---
--- How much the input has changed. Especially useful for movement and joysticks.
--- @field Delta number|Vec2
---
--- Which gamepad/player this came from (always 1 for keyboard/mouse).
--- @field UserIndex number
