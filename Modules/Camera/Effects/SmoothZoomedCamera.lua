local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NevermoreEngine   = require(ReplicatedStorage:WaitForChild("NevermoreEngine"))
local LoadCustomLibrary = NevermoreEngine.LoadLibrary

local CameraState = LoadCustomLibrary("CameraState")
local SummedCamera = LoadCustomLibrary("SummedCamera")
local SpringPhysics = LoadCustomLibrary("SpringPhysics")

-- Intent: Allow freedom of movement around a current place, much like the classic script works now.
-- Not intended to be use with the current character script

-- Intended to be used with a SummedCamera, relative.

--[[ API

	local Zoom = SmoothZoomedCamera.new()
	Zoom.Zoom = 30 -- Distance from original point
	Zoom.MaxZoom = 100 -- Max distance away
	Zoom.MinZoom = 0.5 -- Min distance away

	-- Assigning .Zoom will automatically clamp
]]
local SmoothZoomedCamera = {}
SmoothZoomedCamera.ClassName = "SmoothZoomedCamera"
SmoothZoomedCamera._MaxZoom = 100
SmoothZoomedCamera._MinZoom = 0.5
SmoothZoomedCamera.BounceAtEnd = true

function SmoothZoomedCamera.new()
	local self = setmetatable({}, SmoothZoomedCamera)

	self.Spring = SpringPhysics.NumberSpring.New()
	self.Speed = 15

	return self
end

function SmoothZoomedCamera:ZoomIn(Value, Min, Max)
	if Min or Max then
		self.Zoom = self.Zoom - math.clamp(Value, Min or -math.huge, Max or math.huge)
	else
		self.Zoom = self.Zoom - Value
	end
end

function SmoothZoomedCamera:Impulse(Value)
	self.Spring:Impulse(Value)
end

function SmoothZoomedCamera:__add(Other)
	return SummedCamera.new(self, Other)
end

function SmoothZoomedCamera:__newindex(Index, Value)
	if Index == "TargetZoom" or Index == "Target" then
		local Target = math.clamp(Value, self.MinZoom, self.MaxZoom)
		self.Spring.Target = Target
		
		if self.BounceAtEnd then
			if Target < Value then
				self:Impulse(self.MaxZoom)
			elseif Target > Value then
				self:Impulse(-self.MinZoom)
			end
		end
	elseif Index == "TargetPercentZoom" then
		self.Target = self.MinZoom + self.Range*Value
	elseif Index == "PercentZoom" then
		self.Zoom = self.MinZoom + self.Range*Value
	elseif Index == "Damper" then
		self.Spring.Damper = Value
	elseif Index == "Value" or Index == "Zoom" then
		self.Spring.Value = math.clamp(Value, self.MinZoom, self.MaxZoom)
	elseif Index == "Speed" then
		self.Spring.Speed = Value
	elseif Index == "MaxZoom" then
		--assert(Value > self.MinZoom, "MaxZoom can't be less than MinZoom")

		self._MaxZoom = Value
	elseif Index == "MinZoom" then
		--assert(Value < self.MaxZoom, "MinZoom can't be greater than MinZoom")

		self._MinZoom = Value
	else
		rawset(self, Index, Value)
	end
end

function SmoothZoomedCamera:__index(Index)
	if Index == "State" or Index == "CameraState" or Index == "Camera" then
		local State = CameraState.new()
		State.Position = Vector3.new(0, 0, self.Zoom)
		return State
	elseif Index == "Zoom" or Index == "Value" then
		return self.Spring.Value
	elseif Index == "TargetPercentZoom" then
		return (self.Target - self.MinZoom) / self.Range
	elseif Index == "PercentZoom" then
		return (self.Zoom - self.MinZoom) / self.Range
	elseif Index == "MaxZoom" then
		return self._MaxZoom
	elseif Index == "MinZoom" then
		return self._MinZoom
	elseif Index == "Range" then
		return self.MaxZoom - self.MinZoom
	elseif Index == "Damper" then
		return self.Spring.Damper
	elseif Index == "Speed" then
		return self.Spring.Speed
	elseif Index == "Target" or Index == "TargetZoom" then
		return self.Spring.Target
	elseif Index == "Velocity" then
		return self.Spring.Velocity
	elseif Index == "HasReachedTarget" then
		return math.abs(self.Value - self.Target) < 1e-4 and math.abs(self.Velocity) < 1e-4
	else
		return SmoothZoomedCamera[Index]
	end
end

return SmoothZoomedCamera