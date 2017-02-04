-- Yohane FLSH abstraction layer
-- Platform for LOVE2D renderer

--[[
-- To initialize Yohane under LOVE2D, example
local Yohane = require("Yohane")						-- Load Yohane FLSH abstraction layer
love.filesystem.load("YohaneLove2DPlatform", sysroot)	-- Set platform-specific functions
Yohane.Init(love.filesystem.load)						-- Initialize Yohane

-- love.filesystem.load is used because loadfile operates
-- on directory where LOVE2D started, which breaks everything.
]]--

local Yohane = require(({...})[1]:gsub("/", ".")..".Yohane")
local love = require("love")

-- Simply set the function. ResolveImage always uses PNG
Yohane.Platform.ResolveImage = love.graphics.newImage

function Yohane.Platform.CloneImage(image_handle)
	-- No cloning needed
	-- You can use same image handle for multiple draws
	return image_handle
end

function Yohane.Platform.Draw(drawdatalist)
	-- The drawdatalist contains table which you need to draw on screen.
	-- The position, colors, scale, and skew data is already in there,
	-- ordered based on their respective layers.
	-- Also the image offset and image translation is already calculated
	-- for you. You just need to draw with offset relative to top-left of the image
	
	local r, g, b, a = love.graphics.getColor()
	
	for _, drawdata in ipairs(drawdatalist) do
		love.graphics.setColor(drawdata.r, drawdata.g, drawdata.b, drawdata.a)
		love.graphics.draw(
			drawdata.image, drawdata.x, drawdata.y,
			drawdata.rotation,
			drawdata.scaleX, drawdata.scaleY
		)
	end
	
	love.graphics.setColor(r, g, b, a)
end

function Yohane.Platform.OpenReadFile(fn)
	local x = assert(love.filesystem.newFile(fn, "r"))
	x:seek(0)
	
	return x
end
