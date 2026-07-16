--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta Widget
-- This file is for the Lua Language Server, do not require it

--- Where a widget is anchored, both to the screen and as its own pivot.
--- For example, "BottomRight" pins the widget's bottom right corner to the bottom right of the screen.
--- @alias Anchor "TopLeft" | "Top" | "TopRight" | "Left" | "Center" | "Right" | "BottomLeft" | "Bottom" | "BottomRight"

--- Represents a single UI element. Every widget shares the base properties below, and each kind adds its own.
--- @class Widget
---
--- The anchor point the widget is positioned from.
--- @field Anchor Anchor
--- The pixel offset from the anchor.
--- @field Offset Vec2
--- The widget's size in pixels.
--- @field Size Vec2
--- Whether the widget and its contents is drawn.
--- @field Visible boolean
---
--- The background fill color. Panels and buttons only.
--- @field Bg Color
--- The border color. Panels and buttons only.
--- @field Border? Color
---
--- The displayed text. Labels and buttons only.
--- @field Text string
--- The color the text is drawn in. Labels and buttons only.
--- @field TextColor Color
--- The font used to render the text. Labels and buttons only.
--- @field Font Font
---
--- "Attaches" a function to the button's click event. Buttons only.
--- The callback is called every time the button is clicked.
--- @field OnClick fun(self: Widget, callback: fun())
