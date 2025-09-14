--!strict
-- Revamped version of boatbomber's VoxelMap (from WindShake)
-- Removed ClassName bucket

local VoxelMap = {}
VoxelMap.__index = VoxelMap

function VoxelMap.new(voxelSize: number?)
	return setmetatable({
		_voxelSize = voxelSize or 50,
		_voxels = {},
	}, VoxelMap)
end

function VoxelMap:_debugDrawVoxel(voxelKey: Vector3)
	local box = Instance.new("Part")
	box.Name = tostring(voxelKey)
	box.Anchored = true
	box.CanCollide = false
	box.Transparency = 1
	box.Size = Vector3.one * self._voxelSize
	box.Position = (voxelKey * self._voxelSize) + (Vector3.one * (self._voxelSize / 2))
	box.Parent = workspace

	local selection = Instance.new("SelectionBox")
	selection.Color3 = Color3.new(0, 0, 1)
	selection.Adornee = box
	selection.Parent = box

	task.delay(1 / 50, box.Destroy, box)
end

function VoxelMap:AddObject(position: Vector3, object: Instance)
	local voxelKey = position // self._voxelSize

	local voxel = self._voxels[voxelKey]

	if voxel then
		table.insert(voxel, object)
	else
		self._voxels[voxelKey] = { object }
	end

	return voxelKey
end

function VoxelMap:RemoveObject(voxelKey: Vector3, object: Instance)
	local voxel = self._voxels[voxelKey]

	if voxel == nil then
		return
	elseif #voxel == 1 then
		if voxel[1] == object then
			voxel[1] = nil
			self._voxels[voxelKey] = nil
		end
		return
	end

	local index = table.find(voxel,object)
	if index then
		-- Swap with last index to avoid shifting
		local n = #voxel
		voxel[index] = voxel[n]
		voxel[n] = nil
	end
end

function VoxelMap:GetVoxelKey(position: Vector3)
	return position // self._voxelSize
end

function VoxelMap:GetVoxelsInRegion(top: Vector3, bottom: Vector3)
	local voxelSize = self._voxelSize
	local min, max = top:Min(bottom) // voxelSize, top:Max(bottom) // voxelSize

	local found = {}
	for y = min.Y, max.Y do
		for x = min.X, max.X do
			for z = min.Z, max.Z do
				local voxelKey = Vector3.new(x, y, z)
				local voxel = self._voxels[voxelKey]
				if voxel then
					found[voxelKey] = voxel
				end
			end
		end
	end

	return found
end

function VoxelMap:ForEachObjectInRegion(top: Vector3, bottom: Vector3, callback: (Instance) -> ())
	for voxelKey, voxel in self:GetVoxelsInRegion(top, bottom) do
		for _, object in voxel do
			callback(object)
		end
	end
end

function VoxelMap:GetVoxelsInView(camera: Camera, distance: number)
	local voxelSize: number = self._voxelSize
	local cameraCFrame = camera.CFrame
	local cameraPos = cameraCFrame.Position
	local rightVec, upVec = cameraCFrame.RightVector, cameraCFrame.UpVector

	local distance2 = distance / 2
	local farPlaneHeight2 = math.tan(math.rad((camera.FieldOfView + 5) / 2)) * distance
	local farPlaneWidth2 = farPlaneHeight2 * (camera.ViewportSize.X / camera.ViewportSize.Y)
	local farPlaneCFrame = cameraCFrame * CFrame.new(0, 0, -distance)
	local farPlaneTopLeft = farPlaneCFrame * Vector3.new(-farPlaneWidth2, farPlaneHeight2, 0)
	local farPlaneTopRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, farPlaneHeight2, 0)
	local farPlaneBottomLeft = farPlaneCFrame * Vector3.new(-farPlaneWidth2, -farPlaneHeight2, 0)
	local farPlaneBottomRight = farPlaneCFrame * Vector3.new(farPlaneWidth2, -farPlaneHeight2, 0)

	local frustumCFrameInverse = (cameraCFrame * CFrame.new(0, 0, -distance2)):Inverse()

	local rightNormal = upVec:Cross(farPlaneBottomRight - cameraPos).Unit
	local leftNormal = upVec:Cross(farPlaneBottomLeft - cameraPos).Unit
	local topNormal = rightVec:Cross(cameraPos - farPlaneTopRight).Unit
	local bottomNormal = rightVec:Cross(cameraPos - farPlaneBottomRight).Unit

	local minBound = cameraPos:Min(farPlaneTopLeft,farPlaneTopRight,farPlaneBottomLeft,farPlaneBottomRight) // voxelSize
	local maxBound = cameraPos:Max(farPlaneTopLeft,farPlaneTopRight,farPlaneBottomLeft,farPlaneBottomRight) // voxelSize

	local function isPointInView(point: Vector3): boolean
		-- Check if point lies outside frustum OBB
		local relativeToOBB = frustumCFrameInverse * point
		if
			relativeToOBB.X > farPlaneWidth2
			or relativeToOBB.X < -farPlaneWidth2
			or relativeToOBB.Y > farPlaneHeight2
			or relativeToOBB.Y < -farPlaneHeight2
			or relativeToOBB.Z > distance2
			or relativeToOBB.Z < -distance2
		then
			return false
		end

		-- Check if point lies outside a frustum plane
		local lookToCell = point - cameraPos
		if
			rightNormal:Dot(lookToCell) < 0
			or leftNormal:Dot(lookToCell) > 0
			or topNormal:Dot(lookToCell) < 0
			or bottomNormal:Dot(lookToCell) > 0
		then
			return false
		end

		return true
	end

	local found = {}
	for y = minBound.Y, maxBound.Y do
		local yMin = y * voxelSize
		local yMax = yMin + voxelSize
		local yPos = math.clamp(farPlaneCFrame.Y, yMin, yMax)

		for x = minBound.X, maxBound.X do
			local xMin = x * voxelSize
			local xMax = xMin + voxelSize
			local xPos = math.clamp(farPlaneCFrame.X, xMin, xMax)

			for z = minBound.Z, maxBound.Z do
				local zMin = z * voxelSize
				local zMax = zMin + voxelSize

				local voxelNearestPoint = Vector3.new(xPos, yPos, math.clamp(farPlaneCFrame.Z, zMin, zMax))
				if isPointInView(voxelNearestPoint) then
					-- Found the first in frustum, now binary search for the last
					local entry, exit = z, minBound.Z - 1
					local left = z
					local right = maxBound.Z

					while left <= right do
						local mid = (left + right) // 2
						local midPos = Vector3.new(
							xPos,
							yPos,
							math.clamp(farPlaneCFrame.Z, mid * voxelSize, mid * voxelSize + voxelSize)
						)

						if isPointInView(midPos) then
							exit = mid
							left = mid + 1
						else
							right = mid - 1
						end
					end

					for fillZ = entry, exit do
						local voxelKey = Vector3.new(x, y, fillZ)
						local voxel = self._voxels[voxelKey]
						if voxel then
							found[voxelKey] = voxel
						end
					end

					break
				end
			end
		end
	end

	return found
end

function VoxelMap:ForEachObjectInView(camera: Camera, distance: number, callback: (Instance) -> ())
	for voxelKey, voxel in self:GetVoxelsInView(camera, distance) do
		for _, object in voxel do
			callback(object)
		end
	end
end

function VoxelMap:ClearAll()
	table.clear(self._voxels)
end

function VoxelMap:Destroy()
	setmetatable(self, nil)
	table.clear(self._voxels :: {})
	self._voxelSize = nil
	self._voxels = nil
end

return VoxelMap
