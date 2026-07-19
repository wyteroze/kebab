--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local Pages = require("core.ui.pages")

local PageHost = {}
PageHost.__index = PageHost

--- @param body Container
function PageHost.new(body)
    return setmetatable({
        body = body,
        built = {},
        active = nil
    }, PageHost)
end

local function key(major, minor)
    return major .. "\0" .. minor
end

local function findPage(major, minor)
    for _, section in ipairs(Pages.sections(major)) do
        if section.name == minor then return section end
    end
end

--- Builds (the first time) and shows the page registered at (major, minor).
--- Any previously shown page is only hidden, not destroyed.
--- @param major string
--- @param minor string
--- @return boolean found
function PageHost:show(major, minor)
    local page = findPage(major, minor)
    if not page then return false end

    local k = key(major, minor)
    local entry = self.built[k]

    if not entry then
        local container = self.body:Container("TopLeft", Vec2.new(0, 0), self.body.Size)
        local update, cleanup = page.build(container)

        entry = {
            container = container,
            update = update,
            cleanup = cleanup,
            interval = page.interval,
            accum = 0
        }
        self.built[k] = entry
    end

    if self.active and self.active ~= entry then
        self.active.container.Visible = false
    end

    entry.container.Visible = true
    entry.accum = entry.interval

    self.active = entry
    return true
end

--- Ticks the page currently being shown, respecting its `interval`. Pages that
--- are built but hidden are not updated. Call every frame (from OnUpdate).
--- @param dt number
function PageHost:update(dt)
    local entry = self.active
    if not entry or not entry.update then return end

    entry.accum = entry.accum + dt
    if entry.accum < entry.interval then return end

    local elapsed = entry.accum
    entry.accum = 0

    entry.update(elapsed)
end

--- Tears down every page built by this host (calling their cleanup functions,
--- if any, then removing their widgets).
function PageHost:closeAll()
    for _, entry in pairs(self.built) do
        if entry.cleanup then entry.cleanup() end
        entry.container:Remove()
    end

    self.built = {}
    self.active = nil
end

return PageHost
