--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta Engine
--- This file is for the Lua Language Server, do not require it

--- The engine's frame info namespace. Access it via `Engine.FrameInfo`
--- This is only updated at the end of every frame. If you want to read it,
--- do so in a PostStep callback for the current frame's info.
--- @class EngineLibFrameInfo
--- The current frame's FPS.
--- @field FPS number
--- The current frame's frame number.
--- @field Frame integer

--- Library for internal engine-related things. You won't use this often.
--- @class EngineLib
--- Engine frame info. Refer to EngineLibFrameInfo
--- @field FrameInfo EngineLibFrameInfo
Engine = {}

--- Quits the engine, closing the program and all windows.
function Engine.quit() end

--- Attach a callback to the very start of the game loop,
--- before the engine processes the frame.
--- @param callback fun()
function Engine.OnPreStep(callback) end

--- Attach a callback to the very end of the game loop,
--- after the engine processes the frame.
--- @param callback fun()
function Engine.OnPostStep(callback) end
