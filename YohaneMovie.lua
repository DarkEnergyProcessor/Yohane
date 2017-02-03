-- Yohane FLSH abstraction layer
-- Class which responsible of the heavy calculation
-- This class is used internally

local Yohane = ({...})[1]
local YohaneMovie = {_internal = {_mt = {}}}

------------------------------
-- Yohane Movie Calculation --
------------------------------
--[[
-- API List

YohaneMovie = YohaneMovie.newMoie(moviedatatable, parentmovielist)
instruction_data = YohaneMovie:getNextInstruction()
instruction = YohaneMovie:findFrame(frame)
is_stopped = YohaneMovie:stepFrame()
YohaneMovie:draw(x, y)
YohaneMovie:jumpLabel(label_name)

]]--

function YohaneMovie.newMovie(moviedata, movielist)
	local mvdata = {
		instruction = moviedata.startInstruction + 4
		currentFrame = 1,
		layers = {},
		drawCalls = {},
		movieList = movielist,
		data = moviedata,	-- Beware, recursive table
		__index = YohaneMoie._internal._mt
	}
	
	return setmetatable({}, mvdata)
end

-- Get next instruction
function YohaneMovie._internal._mt.getNextInstruction(this)
	local inst
	
	this = getmetatable(this)
	inst = this.data.instructionData[this.instruction]
	this.instruction = this.instruction + 1
	
	return inst
end

-- Get new instruction code of frame
function YohaneMovie._internal._mt.findFrame(this, frame)
	local uiFrame = 0
	local instTab
	
	this = getmetatable(this)
	instTab = this.data.instructionData
	
	do
		local i = this.data.startInstruction
		
		while i < this.data.endInstruction do
			local inst = instTab[i]
			
			if inst == 0 then		-- SHOW_FRAME
				i = i + 3
				uiFrame = uiFrame + 1
				
				if uiFrame == frame then
					return i - 4
				end
			elseif inst == 1 then	-- PLACE_OBJECT
				i = i + 4
			elseif inst == 2 or inst == 3 then -- REMOVE_OBJECT or PLAY_SOUND
				i = i + 1
			elseif inst == 4 then	-- PLACE_OBJECT_CLIP
				i = i + 5
			else
				assert(false, "Invalid instruction")
			end
		end
	end
	
	return this.data.startInstruction + 4
end

-- Heavy calculation starts here :v
function YohaneMovie._internal._mt:stepFrame()
	local this = getmetatable(self)
	local frozen = false
	
	-- Clear draw calls here
	for i = #this.drawCalls, 1, -1 do
		this.drawCalls[i] = nil
	end
	
	repeat
		local instr = self:getNextInstruction()
		
		if instr == 0 then
			-- SHOW_FRAME
			local label = self:getNextInstruction()
			local frame_type = self:getNextInstruction()
			local frame_target = self:getNextInstruction()
			
			if frame_type == 0 then
				-- STOP_INSTRUCTION
				frozen = true
			elseif frame_type == 1 then
				-- GOTO_AND_PLAY
				this.instruction = self:findFrame(frame_target)
			elseif frame_type == 2 then
				-- GOTO_AND_STOP
				this.instruction = self:findFrame(frame_target)
				frozen = true
			end
			
			-- TODO: calculate and put all draw calls here
		elseif instr == 1 or instr == 4 then
			-- PLACE_OBJECT or PLACE_OBJECT_CLIP
			local movieID = self:getNextInstruction()
			local matrixIdx = self:getNextInstruction()
			local matrixColIdx = self:getNextInstruction()
			local layer = self:getNextInstruction()
			
			if instr == 4 then
				self:getNextInstruction()	-- Clip layer
			end
			
			-- TODO: calculate layers in here
		elseif instr == 2 then
			-- REMOVE_OBJECT
			this.layers[self:getNextInstruction()] = nil
		elseif instr == 3 then
			-- PLAY_SOUND
			-- unimplemented
			self:getNextInstruction()
		else
			assert(false, "Invalid instruction")
		end
	until instr == 0
	
	return frozen
end
