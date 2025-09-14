-- Add under an Actor named "Replicator"
local plr:Player = game.Players:FindFirstChild(script.Parent.Name)
if not plr then return end

local char = plr.Character
local root:Part = char and char:FindFirstChild'RootPart' -- Change if necessary

local targetCf = root and root.CFrame or CFrame.identity
local oldCf = targetCf
local t = 1

plr.CharacterAdded:Connect(function(_char)
	char = _char
	root = char:WaitForChild'RootPart'
	root.Anchored = true
	targetCf = root.CFrame
	oldCf = targetCf
end)

script.Parent:BindToMessageParallel('Root',function(cf)
	oldCf, targetCf, t = oldCf:Lerp(targetCf,(t > .0357 and .0357 or t)*28), cf, 0
end)

-- This wont use Time.PreRender because it is based on players' speed
game:GetService'RunService'.PreRender:Connect(function(dt)
	if not root then return end
	t += dt
	root.CFrame = oldCf:Lerp(targetCf,(t > .0357 and .0357 or t)*28)
end)
