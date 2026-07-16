--[[
Copyright 2026 wyteroze. Licensed under the Apache License, Version 2.0.
--]]

--- @meta Color
--- This file is for the Lua Language Server, do not require it

--- A collection of colors from the official W3C list of named colors. https://www.w3.org/TR/css-color-4/#named-colors
--- @alias ColorName "Alice Blue" | "Antique White" | "Aqua" | "Aquamarine" | "Azure" | "Beige" | "Bisque" | "Black" | "Blanched Almond" | "Blue" | "Blue Violet" | "Brown" | "Burly Wood" | "Cadet Blue" | "Chartreuse" | "Chocolate" | "Coral" | "Cornflower Blue" | "Cornsilk" | "Crimson" | "Cyan" | "Dark Blue" | "Dark Cyan" | "Dark Goldenrod" | "Dark Gray" | "Dark Green" | "Dark Grey" | "Dark Khaki" | "Dark Magenta" | "Dark Olive Green" | "Dark Orange" | "Dark Orchid" | "Dark Red" | "Dark Salmon" | "Dark Sea Green" | "Dark Slate Blue" | "Dark Slate Gray" | "Dark Slate Grey" | "Dark Turquoise" | "Dark Violet" | "Deep Pink" | "Deep Sky Blue" | "Dim Gray" | "Dim Grey" | "Dodger Blue" | "Firebrick" | "Floral White" | "Forest Green" | "Fuchsia" | "Gainsboro" | "Ghost White" | "Gold" | "Goldenrod" | "Gray" | "Green" | "Green Yellow" | "Grey" | "Honeydew" | "Hot Pink" | "Indian Red" | "Indigo" | "Ivory" | "Khaki" | "Lavender" | "Lavender Blush" | "Lawn Green" | "Lemon Chiffon" | "Light Blue" | "Light Coral" | "Light Cyan" | "Light Goldenrod Yellow" | "Light Gray" | "Light Green" | "Light Grey" | "Light Pink" | "Light Salmon" | "Light Sea Green" | "Light Sky Blue" | "Light Slate Gray" | "Light Slate Grey" | "Light Steel Blue" | "Light Yellow" | "Lime" | "Lime Green" | "Linen" | "Magenta" | "Maroon" | "Medium Aquamarine" | "Medium Blue" | "Medium Orchid" | "Medium Purple" | "Medium Sea Green" | "Medium Slate Blue" | "Medium Spring Green" | "Medium Turquoise" | "Medium Violet Red" | "Midnight Blue" | "Mint Cream" | "Misty Rose" | "Moccasin" | "Navajo White" | "Navy" | "Old Lace" | "Olive" | "Olive Drab" | "Orange" | "Orange Red" | "Orchid" | "Pale Goldenrod" | "Pale Green" | "Pale Turquoise" | "Pale Violet Red" | "Papaya Whip" | "Peach Puff" | "Peru" | "Pink" | "Plum" | "Powder Blue" | "Purple" | "Rebecca Purple" | "Red" | "Rosy Brown" | "Royal Blue" | "Saddle Brown" | "Salmon" | "Sandy Brown" | "Sea Green" | "Seashell" | "Sienna" | "Silver" | "Sky Blue" | "Slate Blue" | "Slate Gray" | "Slate Grey" | "Snow" | "Spring Green" | "Steel Blue" | "Tan" | "Teal" | "Thistle" | "Tomato" | "Turquoise" | "Violet" | "Wheat" | "White" | "White Smoke" | "Yellow" | "Yellow Green"

--- Represents a color.
--- @class Color
---
--- Gets the color name of the color. If the color doesn't exist in the list of color names, it returns the name closest to the color.
--- @field GetName fun(self: Color): ColorName
--- Gets the ARGB components of the color, ranging from 0-255.
--- @field GetARGB fun(self: Color): integer, integer, integer, integer
--- Gets the hex code of the color. formatted as "AARRGGBB"
--- @field GetHex fun(self: Color): string

--- Library for color-related things.
--- @class ColorLib
Color = {}

--- Creates a color from a predefined list of colors. You can optionally provide an alpha (0-255), otherwise the color will be fully opaque.
--- @param colorName ColorName
--- @param alpha integer?
--- @return Color
function Color.fromName(colorName, alpha) end

--- Creates a color with the provided ARGB components. Each component ranges from 0-255
--- @param a integer
--- @param r integer
--- @param g integer
--- @param b integer
--- @return Color
function Color.fromARGB(a, r, g, b) end

--- Creates a color with the provided hex code. The expected format is "AARRGGBB", but you may prefix it, like "0xFF00FF00"
--- @param hexCode string
--- @return Color
function Color.fromHex(hexCode) end
