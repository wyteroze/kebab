--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local theme = require("core.ui.shared")

local BUTTON_SIZE = 10

local font = Assets.loadFont("Oaboe")

local Popup = {}
Popup.__index = Popup

--- @param container Container
--- @param color Color
local function iconButton(container, color, onClick, tx)
    local button = container:Button("Center", Vec2.new(0, 0), Vec2.new(BUTTON_SIZE, BUTTON_SIZE), tx)
    button.Bg = color
    button.Font = font
    button.BorderColor = Color.fromARGB(192, 0, 0, 0)
    button:OnMouseUp(function() onClick() end)

    return button
end

--- @param window Window
--- @param size Vec2
--- @param minimizable boolean
--- @return Container
local function buildTitlebar(window, size, minimizable)
    local bg = window.UI:Panel("TopLeft", Vec2.new(0, 0), Vec2.new(size.X, theme.TITLEBAR_H))
    local bar = window.UI:Container("TopLeft", Vec2.new(0, 0), Vec2.new(size.X, theme.TITLEBAR_H))
    bg.Bg = theme.SURFACE_HI
    bg.BorderColor = theme.BORDER
    bg.BorderSize = theme.BORDER_SIZE

    bar:OnDrag(function(delta) window.Position = window.Position + delta end)

    local title = bar:Label("TopLeft", Vec2.new(6, 6), window.Title)
    title.Font = font
    title.FontScale = 1
    title.TextColor = theme.TEXT_MUTED

    local buttonContainer = bar:Container("Right", Vec2.new(-3, 0), Vec2.new(64, BUTTON_SIZE))

    iconButton(buttonContainer, theme.WARN, function() window:Minimize() end, "-")
    iconButton(buttonContainer, theme.DANGER, function() window:Close() end, "x")
    buttonContainer.Align = "End"
    buttonContainer:StackHorizontal(2)

    return bar
end

--- Creates a new popup window with the given name, size, and options.
--- @param name string
--- @param size Vec2
--- @param opts table? fields: scale (number), resizable (boolean), minimizable (boolean)
function Popup.new(name, size, opts)
    assert(type(name) == "string", "a popup needs a name")
    opts = opts or {}

    local window = Window.new(name, size.X, size.Y, opts.scale or 2, false, false, opts.resizable == true)

    local background = window.UI:Panel("TopLeft", Vec2.new(0, 0), Vec2.new(size.X, size.Y))
    background.Bg = theme.BG
    background.BorderColor = theme.BORDER
    background.BorderSize = theme.BORDER_SIZE

    local body_size = Vec2.new(size.X, size.Y - theme.TITLEBAR_H)
    local body = window.UI:Container("TopLeft", Vec2.new(0, theme.TITLEBAR_H), body_size)

    local titlebar = buildTitlebar(window, size, opts.minimizable == true)
    window:Focus()

    local self = setmetatable({
        window   = window,
        titlebar = titlebar,
        body     = body,
        bodySize = body_size,
    }, Popup)

    return self
end

function Popup:close()
    self.window:Close()
end

return Popup
