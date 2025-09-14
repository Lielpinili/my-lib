-- Under ConsoleServer
local Commands = {}

local plrs = game.Players

local function FindPlayer(sender,plr)
	if plr == '@self' then
		return sender
	end
	return plrs:FindFirstChild(plr)
end
local function FindPlayers(sender,plr)
	if plr:sub(1,1) == "@" then
		local s = plr:sub(2)
		if s == 'all' then
			return plrs:GetPlayers()
		elseif s == 'self' then
			return {sender}
		elseif s == 'others' then
			local t = plrs:GetPlayers()
			table.remove(t,table.find(t,sender))
		end
	else
		local targets = string.split(plr,'|')
		local t = {}
		for _, v in targets do
			local p = plrs:FindFirstChild(v)
			if p then
				table.insert(t,p)
			end
		end
		return t
	end
end
local function Assert(val,type,s)
	local n = typeof(val) == type
	if type == 'number' then
		n = tonumber(val)
	end
	if not n then
		return `{s} argument expected {type}, got {typeof(val)}`
	end
end

Commands.tp = function(sender:Player,plr1:string,plr2:string)
	local err = Assert(plr1,'string','Players')
	err = err or Assert(plr2,'string','Player')
	if err then return 2,err end

	local victims:{Player} = FindPlayers(sender,plr1)
	if #victims == 0 then return 2,`No players found using '{plr1}'` end
	local target:Player = FindPlayer(sender,plr2)
	if not target then return 2,`No player found with '{plr2}'` end

	local char = target.Character
	local targetPos = char and char:GetPivot()
	if not targetPos then return 2,'Target player has no character' end

	local success = 0
	for _, v in victims do
		local char2 = v.Character
		if char2 then
			success += 1
			char2:PivotTo(targetPos)
		end
	end

	return 0,`Teleported {success} players to {char.Name}`
end

Commands.sethp = function(sender:Player,plr:string,hp:number)
	local err = Assert(plr,'string','Players')
	err = err or Assert(hp,'number','Health')
	if err then return 2,err end

	local targets:{Player} = FindPlayers(sender,plr)
	if #targets == 0 then return 2,`No players found using '{plr}'` end

	local success = 0
	for _, v in targets do
		local char = v.Character
		local hum = char and char:FindFirstChildWhichIsA'Humanoid'
		if hum then
			success += 1
			hum.Health = hp
		end
	end

	return 0,`Set {success} players' health to {hp}`
end

Commands.setmaxhp = function(sender:Player,plr:string,hp:number)
	local err = Assert(plr,'string','Players')
	err = err or Assert(hp,'number','Health')
	if err then return 2,err end

	local targets:{Player} = FindPlayers(sender,plr)
	if #targets == 0 then return 2,`No players found using '{plr}'` end

	local success = 0
	for _, v in targets do
		local char = v.Character
		local hum = char and char:FindFirstChildWhichIsA'Humanoid'
		if hum then
			success += 1
			hum.MaxHealth = hp
		end
	end

	return 0,`Set {success} players' max health to {hp}`
end


-- Import custom commands
--for cmd, v in require(script.name) do
--	Commands['name:'..cmd] = v
--end

return Commands
