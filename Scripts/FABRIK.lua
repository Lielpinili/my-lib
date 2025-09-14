--!strict
local run = game:GetService'RunService'

local fabrik = {}
local joint = {}
joint.__index = joint

local function deepClear(t)
	for i, v in pairs(t) do
		t[i] = nil
		if type(v) == "table" then deepClear(v) end
	end
end

function fabrik.Compute(Points:{Vector3},End:Vector3,Length:{number})
	if #Points == 2 then
		Points[2] = (End - Points[1]).Unit * (Points[2] - Points[1]).Magnitude
		return Points
	elseif #Points == 1 then return Points
	end

	local pointsN = #Points
	local lines = pointsN-1
	local Start = Points[1]

	Points[pointsN] = End
	for i = lines, 1, -1 do
		local p = Points[i+1]
		Points[i] = p+(Points[i]-p).Unit*Length[i]
	end

	Points[1] = Start
	for i = 1, lines do
		local p = Points[i]
		Points[i+1] = p+(Points[i+1]-p).Unit*Length[i]
	end
	return Points
end

function fabrik.Create(Direction:Vector3,Parts:{Part},Rotation:CFrame):joint
	local joints = setmetatable({},joint)
	local Points = table.create(#Parts,Parts[1].Position)
	joints.Pos = Points
	joints.Length = Direction.Magnitude

	joints.Start = nil::Part?
	joints.End = nil::Part?
	joints.Parts = Parts
	joints.Rotation = Rotation

	local p, len = Points, table.create(#Parts-1,joints.Length)
	joints._c0 = run.Heartbeat:Connect(function()
		local move = false
		if joints.Start then
			p[1] = joints.Start.Position
			move = true
		end
		if joints.End then
			p[#p] = joints.End.Position
			move = true
		end
		if move then
			fabrik.Compute(p,p[#p],len)
			for i, v:Part in next, Parts, 1 do
				v.CFrame = CFrame.lookAt(p[i-1]:Lerp(p[i],.5),p[i]) * Rotation
			end
		end
	end)

	for i, v in next, Points, 1 do
		Points[i] = v + Direction * (i-1)
	end
	return joints
end


function joint.Follow(self:joint,Part:Part)
	self.End = Part
end
function joint.Stop(self:joint)
	self.End = nil
end

function joint.Move(self:joint, Pos:Vector3)
	run.Heartbeat:Wait()
	self.Pos[1] = Pos
end
function joint.Stick(self:joint, Part:Part)
	self.Start = Part
end
function joint.Detach(self:joint)
	self.Start = nil
end

function joint.Destroy(self:joint)
	self._c0:Disconnect()
	local t:{any} = self.Pos
	for i in pairs(t) do
		t[i] = nil
	end
	t = self.Parts
	for i in pairs(t) do
		t[i] = nil
	end
	for i in pairs(self) do
		self[i] = nil
	end
	setmetatable(self::joint&{},nil)
end

type joint = typeof(fabrik.Create(Vector3.yAxis,{},CFrame.identity))

return fabrik
