--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

local Pages = {}

local DEFAULT_INTERVAL = 0.2

local majorOrder = {}
local majorSeen  = {}
local sections   = {}

--- Registers a page under a major tab / minor section, creating the major tab
--- the first time it's referenced. `build(body)` is called the first time the
--- page is shown. `body` is an empty Container with the same size as the Inspector's
--- content area.
---
--- Like a footer item, `build` can return an
--- `update(elapsed)` function, called every `interval` seconds with the time
--- since its own last update, and a cleanup function as a second value, called
--- if the page is torn down.
---
--- Only the page currently being shown is updated, so a page that's been built
--- but is hidden behind another tab costs nothing.
--- @param major string
--- @param minor string
--- @param build fun(body: Container): (fun(elapsed: number)?), (fun()?)
--- @param opts table? fields: interval (number, default 0.2; use 0 to update every frame)
function Pages.register(major, minor, build, opts)
    assert(type(major) == "string" and type(minor) == "string", "a page needs a major and minor name")
    assert(type(build) == "function", "a page needs a build(body) function")

    opts = opts or {}

    if not majorSeen[major] then
        majorSeen[major] = true
        table.insert(majorOrder, major)
        sections[major] = {}
    end

    table.insert(sections[major], {
        name = minor,
        build = build,
        interval = opts.interval or DEFAULT_INTERVAL
    })
end

--- The list of registered major tab names.
--- @return string[]
function Pages.majors()
    return majorOrder
end

--- The list of sections registered under a major tab.
--- @param major string
--- @return {name: string, build: fun(body: Container): (fun(elapsed: number)?), teardown: (fun()?), interval: number}[]
function Pages.sections(major)
    return sections[major] or {}
end

return Pages
