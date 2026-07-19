--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

-- CORE INIT --

-- Allow requires to search relative to src/assets/scripts/
package.path = "src/assets/scripts/?.lua;" .. package.path

---------------

-- Variables --
local theme = require("core.ui.shared")
local Pages  = require("core.ui.pages")
local Footer = require("core.ui.footer")

---------------

-- Register Inspector elements --

-- Console --
Pages.register("Console", "Log", function(body)
    local lbl = body:Label("Center", Vec2.new(0, 0), "Nothing here yet..")
    lbl.Font = Assets.loadFont("Oaboe")
    lbl.TextColor = theme.TEXT_MUTED
end)
Pages.register("Console", "Repl", function(body)

end)
Pages.register("Console", "Lua", function(body)

end)
-------------

-- Performance --
Pages.register("Performance", "Overview", function(body)

end)
Pages.register("Performance", "Flamegraph", function(body)

end)
Pages.register("Performance", "Breakdown", function(body)

end)
Pages.register("Performance", "Threads", function(body)

end)
-----------------

-- Rendering --
Pages.register("Rendering", "Pipeline", function(body)

end)
Pages.register("Rendering", "Stats", function(body)

end)
Pages.register("Rendering", "Windows", function(body)

end)
---------------

-- Audio --
Pages.register("Audio", "Overview", function(body)

end)
Pages.register("Audio", "Sources", function(body)

end)
Pages.register("Audio", "Device", function(body)

end)
-----------

-- Physics (stub) --
Pages.register("Physics", "Simulation", function(body)

end)
Pages.register("Physics", "Collision", function(body)

end)
Pages.register("Physics", "Bodies", function(body)

end)

------------

-- Memory --
Pages.register("Memory", "Usage", function(body)

end)
Pages.register("Memory", "Subsystems", function(body)

end)
Pages.register("Memory", "Render", function(body)

end)
------------

-- Register footer --

Footer.register("Left", function(group)
    local label = Footer.label(group, "0 fps")
    label.Anchor = "Left"
    label.Offset = Vec2.new(2, 0)

    return function() label.Text = ("frame %d"):format(Engine.FrameInfo.Frame) end
end)


Footer.register("Right", function(group)
    local label = Footer.label(group, "frame 0")
    label.Anchor = "Right"
    label.Offset = Vec2.new(-2, 0)

    return function() label.Text = ("%3.0f fps"):format(Engine.FrameInfo.FPS) end
end)

-------------------------------------


-- Engine.OnPostStep(function()
--     print(Engine.FrameInfo.FPS)
--     print(Engine.FrameInfo.Frame)
-- end)
