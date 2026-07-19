--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local popup    = require("core.ui.popup")
local theme    = require("core.ui.shared")
local TabBar   = require("core.ui.tabbar")
local Footer    = require("core.ui.footer")
local Pages    = require("core.ui.pages")
local PageHost = require("core.ui.pagehost")

local font        = Assets.loadFont("Oaboe")
local logo1x      = Assets.loadImage("icons/CrystalCompact1x.bmp")
local ENGINE_NAME = "Crystal"
local SHOW_ENGINE = true
local POPUP_NAME = "Inspector"

local inspector = {}
inspector.opened = false
inspector.popup  = nil

--- @param window Window
--- @return Container
local function surface(window, anchor, offset, size)
    local container = window.UI:Container(anchor, offset, size)
    container.Bg = theme.SURFACE
    container.BorderColor = theme.BORDER
    container.BorderSize = theme.BORDER_SIZE

    return container
end

local function buildTitle(pop)
    pop.titlebar:Image("TopLeft", Vec2.new(4, 3), Vec2.new(12, 12), logo1x)

    local title = pop.titlebar:GetChild(1)
    title.Anchor = "Top"
    title.Offset = title.Offset - Vec2.new(12, 0)

    if SHOW_ENGINE then
        local engineName = pop.titlebar:Label("TopLeft", Vec2.new(20, 6), ENGINE_NAME:lower())
        engineName.TextColor = theme.ACCENT
        engineName.Font = font
    end
end

--- Opens the Inspector. Does nothing if already open.
function inspector:open()
    if self.opened then return end
    self.opened = true

    local size = Vec2.new(480, 270)
    local pop = popup.new(POPUP_NAME, size, { minimizable = true, scale = 2 })
    self.popup = pop

    buildTitle(pop)

    local topSize = Vec2.new(size.X, 20)
    local topContainer = surface(pop.window, "TopLeft", Vec2.new(0, theme.TITLEBAR_H - 1), topSize)

    local footerSize = Vec2.new(size.X, 12)
    local footerContainer = surface(pop.window, "BottomLeft", Vec2.new(0, 0), footerSize)

    local sideSize = Vec2.new(80, size.Y - theme.TITLEBAR_H - topSize.Y - footerSize.Y + 3)
    local sideContainer = surface(pop.window, "TopLeft", Vec2.new(0, theme.TITLEBAR_H + topSize.Y - 2), sideSize)

    local body = pop.body
    body.Offset = body.Offset + Vec2.new(sideSize.X, topSize.Y)
    body.Size = body.Size - Vec2.new(sideSize.X, topSize.Y + footerSize.Y)

    local majorTabs = TabBar.new(topContainer, {
        horizontal = true, align = "Center", padding = 2,
        selectorAnchor = "Left", selectorStartOffset = Vec2.new(-64, 0), -- fly in, once
    })

    local minorButtonSize = Vec2.new(sideSize.X, 24)
    local minorTabs = TabBar.new(sideContainer, {
        horizontal = false, align = "Start", padding = 0,
        buttonSize = minorButtonSize, selectorSize = minorButtonSize, selectorColor = theme.BG,
    })
    minorTabs.selector.BorderColor = theme.BORDER
    minorTabs.selector.BorderSize = theme.BORDER_SIZE
    minorTabs.selector.BorderRight = false

    local footer = Footer.new(footerContainer)

    local host = PageHost.new(body)

    minorTabs.onSelect = function(section) host:show(self.currentMajor, section.name) end
    majorTabs.onSelect = function(major)
        self.currentMajor = major
        minorTabs:setItems(Pages.sections(major))
        minorTabs:select(1)
    end

    majorTabs:setItems(Pages.majors())
    majorTabs:select(1)

    self.majorTabs = majorTabs
    self.minorTabs = minorTabs
    self.footer = footer
    self.host = host

    pop.window:OnUpdate(function(dt)
        majorTabs:update(dt)
        minorTabs:update(dt)
        host:update(dt)
        footer:update(dt)
    end)
    pop.window:OnClose(function()
        self.opened = false
        self.popup = nil
    end)
end

--- Closes the Inspector. Does nothing if already closed.
function inspector:close()
    if not self.opened then return end
    self.opened = false

    if self.footer then self.footer:destroy() end
    if self.host then self.host:closeAll() end
    if self.popup then self.popup:close() end

    self.popup = nil
    self.host = nil
    self.footer = nil
end

--- Toggles whether the Inspector is open or not.
function inspector:toggleOpen()
    if not self.opened then
        self:open()
    else
        self:close()
    end
end

return inspector
