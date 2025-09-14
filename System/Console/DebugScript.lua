local run = game:GetService'RunService'

local plr = game.Players.LocalPlayer
local frame = script.Parent


local fpsText = frame:WaitForChild'FPS'
local frames = {}
local t = 0
run.PreRender:Connect(function(dt)
	t += dt

	for i = #frames, 1, -1 do
		local v = frames[i]
		frames[i+1] = t - v < 1 and v or nil
	end
	frames[1] = t

	fpsText.Text = 'FPS: '..#frames
end)

-- Change depending on your system
local playStateText = frame:WaitForChild'PlayState'
local c = plr:GetAttributeChangedSignal'PlayState':Connect(function()
	playStateText.Text = 'Play: '..plr:GetAttribute'PlayState'
end)
playStateText.Text = 'Play: '..plr:GetAttribute'PlayState'


local pingText = frame:WaitForChild'Ping'
local pingRE = frame:WaitForChild'PingRE'
local receive = 0
pingRE.OnClientEvent:Connect(function()
	receive = t
end)
while true do
	local start = t
	receive = nil
	pingRE:FireServer()
	repeat task.wait(1)
		if receive then
			pingText.Text = 'Ping: '..(receive - start)//.001
 		elseif tonumber(pingText.Text:sub(7)) < (t - start)*1000 then
			pingText.Text = 'Ping: '..(t - start)//.001
		end
	until receive
end
