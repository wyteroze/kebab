--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local theme = require("core.ui.shared")

local font = Assets.loadFont("Oaboe")
local BUTTON_PADDING = Vec2.new(15, 6)
local LERP_SPEED = 15

local TabBar = {}
TabBar.__index = TabBar

--- TabBar owns two children of `container`, created in this order: the
--- selector panel, then the button-holding container. Widgets paint in
--- creation order, so this ordering is what keeps the selector BEHIND the
--- buttons -- don't create anything else under `container` in between.
---
--- @param container Container both the selector and the buttons are created inside
--- @param opts table? fields: horizontal (boolean, default true), align ("Start"|"Center"|"End",
---   default "Center"), padding (number, default 2), buttonSize (Vec2?, overrides per-button text
---   measuring), selectorColor (Color?), selectorAnchor (Anchor?, default "TopLeft"),
---   selectorStartOffset (Vec2?, default (0,0)), selectorSize (Vec2?, default (0,0) -- the size the
---   selector starts at and grows/glides from on the first selection; pass the real target size
---   (e.g. matching buttonSize) to make the first selection snap in with no visible "grow" animation)
function TabBar.new(container, opts)
    opts = opts or {}

    local selectorStartOffset = opts.selectorStartOffset or Vec2.new(0, 0)
    local selectorStartSize = opts.selectorSize or Vec2.new(0, 0)

    local selector = container:Panel(opts.selectorAnchor or "TopLeft", selectorStartOffset, selectorStartSize)
    selector.Bg = opts.selectorColor or theme.ACCENT
    selector.Visible = false

    local buttons = container:Container("TopLeft", Vec2.new(0, 0), container.Size)

    local self = setmetatable({
        parent = buttons,
        selector = selector,
        selectorStartOffset = selectorStartOffset,
        selectorStartSize = selectorStartSize,
        horizontal = opts.horizontal ~= false,
        buttonSize = opts.buttonSize,
        onSelect = opts.onSelect,
        buttons = {},
        items = {},
        selectedIndex = nil,
    }, TabBar)

    buttons.Align = opts.align or "Center"
    if self.horizontal then
        buttons:StackHorizontal(opts.padding or 2)
    else
        buttons:StackVertical(opts.padding or 0)
    end

    return self
end

--- Replaces the list of items. Each item is either a string, or a table with
--- a `.name` field (the item itself is passed back to you via OnSelect).
--- @param items (string|{name: string})[]
function TabBar:setItems(items)
    self.parent:Clear()
    self.buttons = {}
    self.items = items
    self.selectedIndex = nil
    self.selector.Visible = false

    self.selector.Offset = self.selectorStartOffset
    self.selector.Size = self.selectorStartSize

    for i, item in ipairs(items) do
        local name = type(item) == "table" and item.name or item
        --- @diagnostic disable-next-line param-type-mismatch
        local size = self.buttonSize or (font:MeasureText(name, 1) + BUTTON_PADDING)

        local b = self.parent:Button("Left", Vec2.new(0, 0), size, name)
        b.Font = font
        b.Bg = Color.fromARGB(0, 0, 0, 0)
        b.TextColor = theme.TEXT_MUTED
        if not self.horizontal then b.Anchor = "Left" end

        b:OnClick(function() self:select(i) end)
        self.buttons[i] = b
    end
end

--- Selects an item by (1 based) index, restyles the buttons, and fires OnSelect.
--- @param index integer
function TabBar:select(index)
    local btn = self.buttons[index]
    if not btn then return end

    if self.selectedIndex then
        local prev = self.buttons[self.selectedIndex]
        if prev then prev.TextColor = theme.TEXT_MUTED end
    end

    self.selectedIndex = index
    btn.TextColor = theme.TEXT
    self.selector.Visible = true

    if self.onSelect then self.onSelect(self.items[index], index) end
end

--- Moves the selector toward the active button. Call every frame (from OnUpdate).
--- @param dt number
function TabBar:update(dt)
    local btn = self.selectedIndex and self.buttons[self.selectedIndex]
    if not btn then return end

    local resolvedSize = btn.ResolvedSize
    if resolvedSize.X == 0 and resolvedSize.Y == 0 then return end

    local rate = math.min(dt, 1) * LERP_SPEED
    local mul = Vec2.new(rate, rate)

    self.selector.Offset = self.selector.Offset + (btn.ResolvedPosition - self.selector.ResolvedPosition) * mul
    self.selector.Size = self.selector.Size + (btn.ResolvedSize - self.selector.ResolvedSize) * mul
end

return TabBar
