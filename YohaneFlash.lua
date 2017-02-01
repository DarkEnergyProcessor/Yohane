-- Yohane FLSH abstraction layer
-- Class which contain Flash data
-- Meant to be loaded via loadstring("YohaneFlash.lua")(YohaneTable)

local Yohane = ({...})[1]
local YohaneFlash = {_internal = {_mt = {}}}

-------------------------------------------
-- Basic conversion, copied from Shelsha --
-------------------------------------------
local function string2dwordu(a)
	local str = a:read(4)
	
	return bit.bor(
		bit.lshift(str:byte(), 24),
		bit.lshift(str:sub(2,2):byte(), 16),
		bit.lshift(str:sub(3,3):byte(), 8),
		str:sub(4,4):byte()
	) % 4294967296
end

local function string2wordu(a)
	local str = a:read(2)
	
	return bit.bor(bit.lshift(str:byte(), 8), str:sub(2,2):byte())
end


local function readstring(stream)
	local len = string2wordu(stream)
	local lensub = (len % 2) == 0 and -3 or -2
	
	return stream:read(len):sub(1, lensub)
end

-------------------------
-- Yohane Flash Reader --
-------------------------
-- Creates Yohane Flash Abstraction from specificed stream
function YohaneFlash._internal.parseStream(stream)
	local flsh = {
		strings = {},
		matrixTransf = {},
		movieData = {},
		instrData = {},
		__index = YohaneFlash._internal._mt
	}
	
	assert(stream:read(4) == "FLSH", "Not a Playground Flash file")
	stream:read(4)	-- Skip size
	
	flsh.name = readstring(stream)
	flsh.msPerFrame = string2wordu(stream)
	
	local stringsCount = string2wordu(stream)
	assert(stringsCount ~= 65535, "Sound extension is not supported at the moment")
	
	-- Read strings data
	for i = 1, stringsCount do
		flsh.strings[i - 1] = readstring(stream)
	end
	
	local matrixCount = string2dwordu(stream)
	local floatsCount = string2dwordu(stream)
	local floats = {}
	
	-- Read float constants
	for i = 1, floatsCount do
		floats[i - 1] = string2dwordu(stream) / 65536
	end
	
	-- Read matrix data
	for i = 1, matrixCount do
		local matrixData = nil
		local mtrxType = stream:read(1):byte()
		local mtrxIdx = string2dwordu(stream)
		
		if mtrxType == 0 then
			-- MATRIX_ID, Identity
			matrixData = {0, 0, 0, 0, 0, 0}
		elseif mtrxType == 1 then
			-- MATRIX_T, Translate
			matrixData = {1, 0, 0, 1, floats[mtrxIdx], floats[mtrxIdx + 1]}
		elseif mtrxType == 2 then
			-- MATRIX_TS, Translation and Scale
			matrixData = {floats[mtrxIdx], 0, 0, floats[mtrxIdx + 1], floats[mtrxIdx + 2], floats[mtrxIdx + 3]}
		elseif mtrxType == 3 then
			-- MATRIX_TG, Translation, Skew, and Scale
			matrixData = {
				floats[mtrxIdx]    , floats[mtrxIdx + 1], floats[mtrxIdx + 2],
				floats[mtrxIdx + 3], floats[mtrxIdx + 4], floats[mtrxIdx + 5]
			}
		elseif mtrxType == 4 then
			-- MATRIX_COL, RGBA color component, from 0.0 to 1.0, so convert to 0-255
			matrixData = {
				floats[mtrxIdx]     * 255,
				floats[mtrxIdx + 1] * 255,
				floats[mtrxIdx + 2] * 255,
				floats[mtrxIdx + 3] * 255
			}
		end
		
		flsh.matrixTransf[i - 1] = matrixData
	end
	
	-- Read instructions
	local instrCount = string2dwordu(stream)
	for i = 1, instrCount do
		flsh.instrData[i - 1] = string2dwordu(stream)
	end
	
	-- Read movie data
	local movieCount = string2dwordu(stream)
	for i = 1, movieCount do
		local moviedata = {string2dwordu(stream), string2dwordu(stream), string2dwordu(stream), string2dwordu(stream)}
		local movie = {}
		
		if moviedata[2] < 0x8000 then
			-- Flash movie
			movie.type = "flash"
			movie.name = flsh.strings[moviedata[1]]
			movie.startInstruction = moviedata[3]
			movie.endInstruction = moviedata[4]
			movie.instructionData = flsh.instrData
			movie.instructionCounter = movie.data
			movie.frameCount = moviedata[2]
			
			flsh.movieData[i - 1] = movie
		elseif moviedata[2] == 0xFFFF then
			-- Image
			movie.type = "image"
			movie.name = flsh.strings[moviedata[1]]
			movie.offsetX = math.floor(moviedata[3] / 32768) * (-65536) + moviedata[3]	-- To signed
			movie.offsetY = math.floor(moviedata[4] / 32768) * (-65536) + moviedata[4]	-- To signed
			movie.imageHandle = Yohane.Platform.ResolveImage(movie.name:sub(2, -6))
			flsh.movieData[i - 1] = movie
		elseif moviedata[2] == 0x8FFF then
			-- Shape
			movie.type = "shape"
			-- No support for shape atm
			
			flsh.movieData[i - 1] = movie
		end
	end
	
	return setmetatable({}, flsh)
end

-- Clones current Yohane instance to new one.
-- Beware that this might increase your memory usage
-- if not used correctly!
function YohaneFlash._internal._mt.clone(this)
end

-- Get Yohane flash movie object from specificed name
-- or from specificed ID
-- This function can be slow since it always creates new
-- instance of Yohane flash movie object
function YohaneFlash._internal._mt.getMovie(this, id)
end

-- Get image object from specificed name or ID
-- The image objecr returned is platform-dependant, example
-- for LOVE2D platform, it will be LOVE2D Image object.
function YohaneFlash._internal._mt.getImage(this, id)
end
