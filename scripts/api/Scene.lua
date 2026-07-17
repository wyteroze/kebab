--[[
    Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
    --]]

--- @meta Scene
-- This file is for the Lua Language Server, do not require it

--- Represents a collection of objects and audio that make up a world.
---
--- A scene holds shared world state; it does not know how it is viewed. Assign a
--- scene to one or more windows with `window.Scene = myScene`, and give each of
--- those windows its own `Camera` to look into it. There is no global "current
--- scene" — rendering is driven entirely by what each window is assigned.
--- @class Scene
---
--- Objects under the scene.
--- @field Objects Object[]
--- Audios under the scene.
--- @field Audios Audio[]
---
--- The image data used for the skybox's texture. It expects a cubemap texture, otherwise the skybox may look bugged.
--- @field SkyboxTexture? ImageData
---
--- Attaches a function to the scene's update event. It is called once per frame
--- with the delta time (in seconds) while the scene is assigned to at least one
--- window. Use this for shared world simulation (moving objects, etc.). For
--- per-window logic like camera movement, use Window:OnUpdate instead.
--- @field OnUpdate fun(self: Scene, callback: fun(delta: number))
---
--- Adds an object to the scene's Objects list, making it visible. Does nothing if the object is already in the scene.
--- @field AddObject fun(self: Scene, object: Object)
---
--- Removes an object from the scene. Does nothing if the object isn't in the scene.
--- @field RemoveObject fun(self: Scene, object: Object)
---
--- Adds an audio to the scene's Audios list, making it audible. Does nothing if the audio is already in the scene.
--- @field AddAudio fun(self: Scene, audio: Audio)
---
--- Removes an audio from the scene. Does nothing if the audio isn't in the scene.
--- @field RemoveAudio fun(self: Scene, audio: Audio)

--- Factory for creating scenes.
--- @class SceneLib
Scene = {}

--- Returns a new Scene.
--- @param name? string
--- @return Scene
function Scene.new(name) end
