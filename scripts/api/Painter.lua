--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta Painter
-- This file is for the Lua Language Server, do not require it

--- A drawing surface handed to a Canvas widget's OnPaint callback.
---
--- All coordinates are local to the canvas: (0, 0) is its top-left corner, and
--- everything you draw is clipped to the canvas' bounds. Angles are in radians.
---
--- The painter is only valid during the OnPaint call it was given to. Don't hold
--- onto it and then draw with it later.
--- @class Painter
---
--- Draws a line between two points.
--- @field Line fun(self: Painter, a: Vec2, b: Vec2, color: Color)
--- Draws a filled rectangle from a top-left position and a size.
--- @field FillRect fun(self: Painter, pos: Vec2, size: Vec2, color: Color)
--- Draws a filled triangle between three points.
--- @field FillTriangle fun(self: Painter, a: Vec2, b: Vec2, c: Vec2, color: Color)
--- Draws a filled circle from a center point and a radius.
--- @field FillCircle fun(self: Painter, center: Vec2, radius: number, color: Color)
--- Draws a filled pie slice from a center and radius, between two angles (in
--- radians). Especially useful for pie charts.
--- @field Wedge fun(self: Painter, center: Vec2, radius: number, start: number, stop: number, color: Color)
--- Draws text at a position.
--- @field Text fun(self: Painter, pos: Vec2, text: string, color: Color)
