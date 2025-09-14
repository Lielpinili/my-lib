local acos = math.acos
local cos = math.cos
local phi = math.pi*2
local sin = math.sin
local rng = Random.new()
local v3Z = Vector3.zAxis
local function RandomCone(axis: Vector3, angle: number)
	local z = cos(rng:NextNumber(0,angle))
	local phi = rng:NextNumber(0,phi)
	local r = (1 - z*z)^.5
	return CFrame.fromAxisAngle(v3Z:Cross(axis), acos(axis:Dot(v3Z))) * Vector3.new(r * cos(phi), r * sin(phi), z)
end
