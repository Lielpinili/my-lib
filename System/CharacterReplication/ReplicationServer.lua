local plrs = game.Players
local rep = game.ReplicatedStorage

local chars = {}

plrs.PlayerAdded:Connect(function(plr)
	local c = plr.CharacterAdded:Connect(function(char)
		chars[plr] = char
	end)

	task.wait()
	plr.AncestryChanged:Wait()
	chars[plr] = nil
	c:Disconnect()
end)

local charRepRE = rep.Events.CharRep
charRepRE.OnServerEvent:Connect(function(plr,cf)
	local char = chars[plr]
	if not char then return end
	for other in chars do
		if other ~= plr then
			charRepRE:FireClient(other,plr.Name,cf)
		end
	end
end)
