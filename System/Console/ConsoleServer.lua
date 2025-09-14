local admins = {
	Lielmaster = 101274783,
	MrMoonlightScarf = 1035109493
}

-- TODO: remove the comments

game.Players.PlayerAdded:Connect(function(plr)
	if admins[plr.Name] == plr.UserId then
		script.ConsoleGui:Clone().Parent = plr.PlayerGui
	end
end)

local cmds = require(script.Commands)
local consoleRequest = Instance.new('RemoteEvent',game.ReplicatedStorage)
consoleRequest.Name = 'ConsoleRequest'
consoleRequest.OnServerEvent:Connect(function(plr,text)
	if admins[plr.Name] == plr.UserId then
		local args = string.split(text,' ')
		local cmd = table.remove(args,1)
		if cmds[cmd] then
			consoleRequest:FireClient(plr,cmds[cmd](plr,unpack(args)))
		end
	end
end)
