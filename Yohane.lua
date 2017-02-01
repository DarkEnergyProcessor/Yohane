-- Yohane FLSH abstraction layer
-- Base tables. You only need to "require" this then
-- call Yohane.Init()

local isInitialized = false
local memreadstream = {}
local Yohane = {
	Platform = {}
}

---------------------------------------------
-- Memory stream code, copied from Shelsha --
---------------------------------------------
function memreadstream.new(buf)
	local len = #buf + 1
	local buffer = ffi.new("uint8_t["..len.."]", buf)
	local out = {
		pos = 0,
		buflen = len,
		initbuf = buffer,
		curbuf = buffer
	}
	
	return setmetatable(out, {__index = memreadstream})
end

function memreadstream.read(this, bytes)
	local afterpos
	local newbuf
	
	if pos == buflen then return end
	
	afterpos = pos + bytes
	
	if afterpos > buflen then
		bytes = bytes - (afterpos - buflen)
	end
	
	newbuf = ffi.string(curbuf, bytes)
	this.curbuf = this.curbuf + bytes
	this.pos = this.pos + bytes
	
	return newbuf
end

function memreadstream.seek(this, whence, offset)
	offset = offset or 0
	whence = whence or cur
	
	if whence == "set" then
		assert(offset > 0 and offset <= buflen, "Invalid seek offset")
		
		this.curbuf = this.initbuf + offset
		this.pos = offset
	elseif whence == "cur" then
		local after = this.pos + offset
		
		assert(after > 0 and after <= buflen, "Invalid seek offset")
		
		this.curbuf = this.curbuf + offset
		this.pos = this.pos + offset
	elseif whence == "end" then
		local after = this.buflen + offset
		
		assert(after > 0 and after <= buflen, "Invalid seek offset")
		
		this.curbuf = this.curbuf + this.buflen + offset
		this.pos = this.buflen + offset
	else
		assert(false, "Invalid seek mode")
	end
	
	return this.pos
end

---------------------------
-- Yohane base functions --
---------------------------

--! @brief Initialize Yohane Flash Abstraction
--! @param loaderfunc Function which behaves like loadfile
--! @param sysroot Where does the library file is located? (forward slash,
--!        without trailing slash)
--! @note Calling this if it's already initialized is no-op
function Yohane.Init(loaderfunc, sysroot)
	if isInitialized then return end
	
	loaderfunc = loaderfunc or loadfile
	
	Yohane.Flash = loaderfunc(sysroot.."YohaneFlash.lua")(Yohane)
	Yohane.Movie = loaderfunc(sysroot.."YohaneMovie.lua")(Yohane)
	isInitialized = true
end

--! @brief Converts string to read-only memory stream
--! @param str String to convert to memory stream
--! @returns new memorystream object
function Yohane.MakeMemoryStream(str)
	return memreadstream.new(str)
end

return Yohane
