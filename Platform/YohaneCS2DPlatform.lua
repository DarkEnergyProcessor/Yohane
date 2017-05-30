-- Yohane FLSH abstraction layer
-- Platform for CS2D renderer

--[[
There are some difficulties while implementing Yohane under CS2D because:
- Images were positioned relative to it's center (except tiles)
- It's not possible to draw image multiple times with same ID
So, it might be more complicated than LOVE2D renderer.

The image ordering also can mess up, this is limitation of CS2D itself because
it's not possible to alter the image ordering without losing much performance.

To imitialize Yohane in CS2D: example
Yohane = dofile("sys/lua/Yohane.lua")		-- Load Yohane FLSH abstraction layer
dofile("sys/lua/YohaneCS2DPlatform.lua")	-- Set platform-specific functions
Yohane.Init(loadfile, "sys/lua")			-- Initialize Yohane

Notice the first line we set Yohane as global table, this is because CS2D
"require" function doesn't look at "sys/lua" folder.
]]

--[[ Example Script
Yohane = dofile("sys/lua/Yohane.lua")		-- Load Yohane FLSH abstraction layer
dofile("sys/lua/YohaneCS2DPlatform.lua")	-- Set platform-specific functions
Yohane.Platform.SetImageMode(2)				-- Image mode 2 = HUD
Yohane.Init(loadfile, "sys/lua")			-- Initialize Yohane

local internalClock = os.clock()
local flsh = Yohane.newFlashFromFilename("sys/lua/Yohane/live_notes_hold_effect.flsh", "ef_326_effect")
local flsh2 = Yohane.newFlashFromFilename("sys/lua/Yohane/live_combo_cheer.flsh", "ef_350")
local tid = timer(20, "test_yohane", "", -1)

flsh2:jumpToLabel("cut_03_loop")

function test_yohane()
	local prevIntClock = internalClock
	internalClock = os.clock()
	local deltaT = (internalClock - prevIntClock) * 1000
	
	flsh2:update(deltaT)
	if flsh2:isFrozen() then
		flsh2:jumpToLabel("cut_03_loop_end")
	end
	
	flsh:update(deltaT)
	flsh2:draw(-50, -50)
	flsh:draw(100, 100)
end
]]

local Yohane = Yohane
local parse = parse
local image = image
local freeimage = freeimage
local imagepos = imagepos
local imagealpha = imagealpha
local imagecolor = imagecolor
local imagescale = imagescale
local GlobalImageMode = 2

local function CreateImageCollectable(path, x, y, mode, pl)
	local id = image(path, x, y, mode, pl)
	local x = newproxy(true)
	local mt = getmetatable(x)
	
	mt.Id = id
	
	function mt.__index(_, var)
		return mt[var]
	end
	
	function mt.__gc(_)
		freeimage(mt.Id)
	end
	
	return x
end

local function GetImageWidthHeight(file)
	local fileinfo = type(file)
	local width, height
	
	if fileinfo == "string" then
		file = assert(io.open(file, "rb"))
	else
		fileinfo = file:seek("cur")
	end
	
	local function refresh()
		if type(fileinfo) == "number" then
			file:seek("set",fileinfo)
		else
			file:close()
		end
	end
	
	file:seek("set", 0)
	-- Detect if PNG
	if file:read(8) == "\137PNG\r\n\26\n" then
		--[[
			The strategy is
			1. Seek to position 0x10
			2. Get value in big-endian order
		]]
		file:seek("set",16)
		
		local widthstr, heightstr={file:read(4):byte(1, 4)}, {file:read(4):byte(1, 4)}
		
		width = widthstr[1] * 16777216 +
				widthstr[2] * 65536 +
				widthstr[3] * 256 +
				widthstr[4]
		height = heightstr[1] * 16777216 +
				 heightstr[2] * 65536 +
				 heightstr[3] * 256 +
				 heightstr[4]
		
		refresh()
		return width, height
	end
	file:seek("set")
	
	-- Detect if BMP
	if file:read(2) == "BM" then
		--[[ 
			The strategy is:
			1. Seek to position 0x12
			2. Get value in little-endian order
		]]
		file:seek("set", 18)
		
		local widthstr, heightstr={file:read(4):byte(1, 4)}, {file:read(4):byte(1, 4)}
		
		width = widthstr[4] * 16777216 +
				widthstr[3] * 65536 +
				widthstr[2] * 256 +
				widthstr[1]
		height = heightstr[4] * 16777216 +
				 heightstr[3] * 65536 +
				 heightstr[2] * 256 +
				 heightstr[1]
		
		refresh()
		return width, height
	end
	
	return nil
end

local function Basename(file)
	local _ = file:reverse()
	return _:sub(1, (_:find("/") or _:find("\\") or #_ + 1) - 1):reverse()
end

-- CS2D renders image relative to center position
-- This function makes it relative to top-left corner instead
local function topleft_rel(iw, ih, rot)
	local r = rot * math.pi / 180
	local a, b = math.cos(-r), math.sin(-r)
	iw, ih = iw * 0.5, ih * 0.5
	
	return a * iw + b * ih, -b * iw + a * ih
end

local function SetImageDataFull(id, x, y, r, sx, sy, colr, colg, colb, cola)
	-- X and Y should be already calculated before passed to this function
	-- rotation should be in degrees
	imagepos(id, x, y, r)
	imagescale(id, sx, sy)
	imagecolor(id, colr, colg, colb)
	imagealpha(id, cola)
end

local ImageManagerFunc = {__index = {
	Draw = function(_, x, y, rot, sx, sy, colr, colg, colb, cola)
		-- cola in 0..1 range
		-- rot in degrees
		local found = false
		for i = 1, #_.ImagePool do
			local a = _.ImagePool[i]
			
			if not(a.Staging) then
				local nx, ny = topleft_rel(_.Width * sx, _.Height * sy, rot)
				
				SetImageDataFull(a.Image.Id, x + nx, y + ny, rot, sx, sy, colr, colg, colb, cola)
				a.Staging = true
				found = true
				
				break
			end
		end
		
		if not(found) then
			local a = {
				Staging = true,
				Image = CreateImageCollectable(_.Path, 0, 0, GlobalImageMode)
			}
			local nx, ny = topleft_rel(_.Width * sx, _.Height * sy, rot)
			
			SetImageDataFull(a.Image.Id, x + nx, y + ny, rot, sx, sy, colr, colg, colb, cola)
			
			_.ImagePool[#_.ImagePool + 1] = a
		end
	end,
	HideUnstaged = function(_)
		for i = 1, #_.ImagePool do
			local a = _.ImagePool[i]
			
			if not(a.Staging) then
				imagealpha(a.Image.Id, 0)
			end
		end
	end,
	ResetStaging = function(_)
		for i = 1, #_.ImagePool do
			_.ImagePool[i].Staging = false
		end
	end,
}}

function Yohane.Platform.ResolveImage(path)
	local cs2dimagepath = "gfx/Yohane/"..Basename(path)
	local w, h = assert(GetImageWidthHeight(cs2dimagepath))
	
	return setmetatable({
		Path = cs2dimagepath,
		Width = w,
		Height = h,
		ImagePool = {}
	}, ImageManagerFunc)
end

function Yohane.Platform.ResolveAudio(path)
	local cs2dsfx = "sfx/Yohane/"..Basename(path)
	local ogg = cs2dsfx..".ogg"
	local wav = cs2dsfx..".wav"
	local x = io.open(ogg, "rb")
	
	if x then
		x:close()
		return ogg
	end
	
	x = io.open(wav, "rb")
		
	if x then
		x:close()
		return wav
	end
	
	return nil
end

function Yohane.Platform.CloneImage(image_handle)
	-- Clone the table
	return setmetatable({
		Path = image_handle.Path,
		Width = image_handle.Width,
		Height = image_handle.Height,
		ImagePool = {}
	}, ImageManagerFunc)
end

function Yohane.Platform.CloneAudio(audio)
	-- Can be used multiple times
	return audio
end

function Yohane.Platform.PlayAudio(audio)
	if audio then
		parse(string.format("sv_sound %q", audio))
	end
end

function Yohane.Platform.Draw(drawdatalist)
	-- The drawdatalist contains table which you need to draw on screen.
	-- The position, colors, scale, and skew data is already in there,
	-- ordered based on their respective layers.
	-- Also the image offset and image translation is already calculated
	-- for you. You just need to draw with offset relative to top-left of the image
	
	-- Note for CS2D renderer: We can't respect the image order because it's
	-- not possible to alter the image order without losing much performance.
	-- It also adds more complexity in this case.
	
	local drawn_images = {}
	
	for i = 1, #drawdatalist do
		local drawdata = drawdatalist[i]
		
		if drawdata.image then
			if not(drawn_images[drawdata.image]) then
				drawn_images[drawdata.image] = drawdata.image
				drawn_images[#drawn_images + 1] = drawdata.image
				
				drawdata.image:ResetStaging()
			end
			
			drawdata.image:Draw(
				drawdata.x, drawdata.y, drawdata.rotation * 180 / math.pi,
				drawdata.scaleX, drawdata.scaleY,
				drawdata.r, drawdata.g, drawdata.b, drawdata.a / 255
			)
		end
	end
	
	for i = 1, #drawn_images do
		drawn_images[i]:HideUnstaged()
	end
end

-- We don't need to define Yohane.Platform.OpenReadFile
-- Yohane will select default "io.open" in this case

-- Should be called before Yohane.Init
function Yohane.Platform.SetImageMode(mode)
	GlobalImageMode = mode
end
