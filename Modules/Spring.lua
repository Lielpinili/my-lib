--!strict
-- Spring code made by EgoMoose
local Spring = {}
local methods = {}

local cos = math.cos
local exp = math.exp
local max = math.max
local sin = math.sin

type n = number
local mt = {__index = methods}
function Spring.new(pos:Vector3, Magnitude:n, Damping:n)
	return setmetatable({
		Target = pos,
		Pos = pos,
		Vel = pos*0,
		Damping = Damping,
		Magnitude = Magnitude,
		_d = Magnitude*Damping,
		_a = Magnitude*(1-Damping*Damping)^.5
	}, mt)
end
type spring = typeof(Spring.new(Vector3.zero,0,0))

function methods:SetMagnitude(Magnitude:number)self = self::spring
	local Damping = self.Damping
	self._d = Magnitude*Damping
	self._a = Magnitude*(1-Damping*Damping)^.5
	self.Magnitude = Magnitude
end
function methods:SetDamping(Damping:number)self = self::spring
	local Magnitude = self.Magnitude
	self._d = Magnitude*Damping
	self._a = Magnitude*(1-Damping*Damping)^.5
	self.Damping = Damping
end

function methods:Step(dt:number)self = self::spring -- Time: 3
	if self._a == 0 then -- For spring with 1 damp
		return self:_stepCritDamp(dt)
	end

	local t = self.Target
	local v = self.Vel
	local d = self._d
	local a = self._a

	local dist = self.Pos - t
	local c2 = (v + dist*d) / a
	local exp = exp(-dt*d)
	local cos = cos(dt*a)
	local sin = sin(dt*a)

	self.Pos = t + exp*(dist*cos + c2*sin)
	self.Vel = -exp*((dist*d - c2*a)*cos + (dist*a + c2*d)*sin)

	return self.Pos
end
function methods:_stepCritDamp(dt:number)self = self::spring -- Time: 2
	local t = self.Target
	local v = self.Vel
	local m = self.Magnitude

	local dist = self.Pos - t
	local s = m*dt
	local exp = exp(-s)

	self.Pos = t + exp*(dist*(1 + s) + v*dt) -- exp*(dist*cos + c2*sin)
	self.Vel = exp*(v*(1 - s) - dist*s*m) -- -exp*((dist*d - c2*a)*cos + (dist*a + c2*d)*sin)

	return self.Pos
end

function methods:Destroy()self = self::spring|{}
	setmetatable(self,nil)
	for i in next, self do
		(self::{})[i] = nil
	end
end

return Spring
