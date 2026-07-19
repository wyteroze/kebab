--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local theme = require("core.ui.shared")

local font = Assets.loadFont("Oaboe")
local DEFAULT_INTERVAL = 0.2
local SIDES = { "Left", "Right" }

local Footer = {}
Footer.__index = Footer

local items = { Left = {}, Right = {} }

--- Registers a footer item. `build(group)` is called every time a Footer is
--- created. `group` is the stacking Container for that side, so the item just
--- creates its widgets inside it and keeps the references it needs.
---
--- `build` may return an `update(elapsed)` function, called every `interval`
--- seconds with the time since its own last update, and a cleanup function as
--- a second value, called when the Footer is destroyed.
--- @param side "Left"|"Right" which end of the footer the item sits at
--- @param build fun(group: Container): (fun(elapsed: number)?), (fun()?)
--- @param opts table? fields: interval (number, default 0.2; use 0 to update every frame)
function Footer.register(side, build, opts)
    assert(items[side], "a footer item needs a side of \"Left\" or \"Right\"")
    assert(type(build) == "function", "a footer item needs a build(group) function")

    opts = opts or {}
    table.insert(items[side], { build = build, interval = opts.interval or DEFAULT_INTERVAL })
end

--- Creates a themed label inside a footer group. Prefer this over group:Label so
--- the footer stays stylistically consistent.
--- @param group Container
--- @param text string
--- @return Label
function Footer.label(group, text)
    local label = group:Label("Left", Vec2.new(0, 0), text)
    label.Font = font
    label.TextColor = theme.TEXT_MUTED

    return label
end

--- Creates a themed button inside a footer group. Prefer this over group:Button so
--- the footer stays stylistically consistent.
--- @param group Container
--- @param text string
--- @param size Vec2
--- @return Button
function Footer.button(group, text, size)
    local button = group:Button("Left", Vec2.new(0, 0), size, text)
    button.Font = font
    button.Bg = theme.SURFACE_HI
    button.TextColor = theme.TEXT
    button.BorderColor = theme.BORDER
    button.BorderSize = theme.BORDER_SIZE

    return button
end

--- Builds a footer inside `container`, running every registered recipe.
---
--- Each side gets its own full-width stacking Container: they overlap, but
--- their runs sit at opposite ends (via Align), so neither has to know how
--- wide the other is. They're exposed as `footer.groups` if an item needs to
--- restyle its own side.
--- @param container Container the footer surface the groups are created inside
--- @param opts table? fields: padding (number, default 6) -- pixels between items
function Footer.new(container, opts)
    opts = opts or {}

    local self = setmetatable({
        container = container,
        groups = {},
        entries = {},
    }, Footer)

    for _, side in ipairs(SIDES) do
        local group = container:Container("TopLeft", Vec2.new(0, 0), container.Size)
        group.Align = (side == "Left") and "Start" or "End"
        group:StackHorizontal(opts.padding or 6)

        self.groups[side] = group

        for _, item in ipairs(items[side]) do
            local update, cleanup = item.build(group)

            if update or cleanup then
                table.insert(self.entries, {
                    update = update,
                    cleanup = cleanup,
                    interval = item.interval,
                    accum = item.interval
                })
            end
        end
    end

    return self
end

--- Ticks every item that has an update function, respecting its `interval`.
--- Call every frame (from OnUpdate).
--- @param dt number
function Footer:update(dt)
    for _, entry in ipairs(self.entries) do
        if entry.update then
            entry.accum = entry.accum + dt

            if entry.accum >= entry.interval then
                local elapsed = entry.accum
                entry.accum = 0

                entry.update(elapsed)
            end
        end
    end
end

--- Runs every item's cleanup function and removes the groups, including
--- all widgets built.
function Footer:destroy()
    for _, entry in ipairs(self.entries) do
        if entry.cleanup then entry.cleanup() end
    end

    for _, group in pairs(self.groups) do
        group:Remove()
    end

    self.entries = {}
    self.groups = {}
end

return Footer
