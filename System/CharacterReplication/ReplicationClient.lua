-- Add a child Actor named "Replicator"
local plrs = game.Players
local rep = game.ReplicatedStorage
local run = game:GetService'RunService'

local charRepRE = rep.Events.CharRep

local mainActor = script:WaitForChild'Replicator'
mainActor.Parent = nil
mainActor.Replicator.Enabled = true

local actors = {}

local function NewPlayer(plr:Player)
	local clone = mainActor:Clone()
	clone.Name = plr.Name
	clone.Parent = script
	actors[plr.Name] = clone
end

for _, plr in plrs:GetPlayers() do
	if plr == plrs.LocalPlayer then continue end
	NewPlayer(plr)
end
plrs.PlayerAdded:Connect(NewPlayer)
plrs.PlayerRemoving:Connect(function(plr)
	if plr ~= plrs.LocalPlayer then
		actors[plr.Name]:Destroy()
		actors[plr.Name] = nil
	end
end)

charRepRE.OnClientEvent:Connect(function(plr,cf)
	actors[plr]:SendMessage('Root',cf)
end)
