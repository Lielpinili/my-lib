--!strict
local Interpolation = {}


---- [[ Bezier ]] ----

local function lerp(a:number,b:number,t:number)
	return a + (b - a)*t
end
Interpolation.Lerp = lerp

function Interpolation.Bezier(ps:{Vector3},t)
	local ps = table.clone(ps)
	for i = #ps-1, 1, -1 do
		for j = 1, i do
			ps[j] = ps[j]:Lerp(ps[j+1],t)
		end
	end
	return ps[1]
end




---- [[ Spline ]] ----

function Interpolation.HermiteSpline(points:{Vector3},vels:{Vector3})
	return function(t:number)
		local index, pt = t//1+1, t%1
		if pt == 0 then
			return points[index]
		end
		local p0, p3 = points[index], points[index+1]
		local p1, p2 = p0 + vels[index], p3 - vels[index+1]
		return pt^3 * (p3 - 3*p2 + 3*p1 - p0) +
			pt^2 * 3*(p2 - 2*p1 + p0) +
			pt * 3*(p1 - p0) +
			p0
	end
end

function Interpolation.CardinalSpline(points:{Vector3},scale:number)
	local vels = {(points[2] - points[1])/3 * scale}
	for i, v in next, points, 2 do
		vels[i-1] = (v - points[i-2])/3 * scale
	end
	vels[#points] = (points[#points] - points[#points-1])/3 * scale

	return Interpolation.HermiteSpline(points,vels)
end



---- [[ Trajectory ]] ----

local terrain = workspace.Terrain
local beam = script:WaitForChild'beam'

local traj = {}
traj.__index = traj
function Interpolation.Trajectory(p,s,t,g) -- Part, speed, time, gravity
	local self = setmetatable({},traj)

	self.p = p
	self.s = s
	self.t = t
	self.g = g

	local beamClone = beam:Clone()
	self.beam = beamClone
	self.att0 = Instance.new('Attachment',p)
	self.att1 = Instance.new('Attachment',p)
	beamClone.Attachment0 = self.att0
	beamClone.Attachment1 = self.att1
	beamClone.Parent = p

	self._c = p.AncestryChanged:Connect(function(_,P)
		if not p then
			self:Destroy()
		end
	end)

	return self
end

function traj:Update(cf:CFrame)
	local x0 = cf.Position
	local v0 = cf.LookVector*self.s
	local t = self.t

	local at, vt = (self.g::Vector3)*t*t, v0*t
	local p3 = at/2 + vt + x0
	local p2 = p3 - (at + vt)/3
	local p1 = ((at - x0-p3)/8 + vt/2 + x0)/.375 - p2

	local r1 = p1 - x0
	local r2 = p2 - p3
	local curve0 = r1.Magnitude
	local curve1 = r2.Magnitude

	r1, r2 = r1/curve0, r2/curve1
	local b = (x0 - p3).Unit
	local u1 = r1:Cross(b).Unit
	local u2 = r2:Cross(b).Unit
	b = u1:Cross(r1).Unit

	local beam:Beam = self.beam
	beam.CurveSize0 = curve1
	beam.CurveSize1 = -curve0

	local pCf:CFrame = self.p.CFrame:Inverse()
	self.att1.CFrame = pCf*CFrame.fromMatrix(x0,r1,u1,b)
	self.att0.CFrame = pCf*CFrame.fromMatrix(p3,r2,u2,b)
end

function traj:Destroy()
	setmetatable(self::{}&typeof(self),nil)
	self.beam:Destroy()
	self.att0:Destroy()
	self.att1:Destroy()
	self._c:Disconnect()
	for i in next, self do
		self[i] = nil
	end
end


return Interpolation
