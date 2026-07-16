--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta UI
-- This file is for the Lua Language Server, do not require it

--- Factory for creating widgets. Every widget created here is drawn on top of the scene.
--- @class UILib
UI = {}

--- Returns a new Panel. A panel is a colored, optionally-bordered rectangle.
--- @param anchor Anchor
--- @param offset Vec2
--- @param size Vec2
--- @return Widget
function UI.Panel(anchor, offset, size) end

--- Returns a new Label. A label is a piece of text. The label sizes itself from its font and text,
--- so no size is given. Set its Font and TextColor to modify how it looks.
--- @param anchor Anchor
--- @param offset Vec2
--- @param text string
--- @return Widget
function UI.Label(anchor, offset, text) end

--- Returns a new Button. A button is a clickable rectangle with a text label. Use OnClick to do something when the button is clicked..
--- @param anchor Anchor
--- @param offset Vec2
--- @param size Vec2
--- @param text string
--- @return Widget
function UI.Button(anchor, offset, size, text) end
