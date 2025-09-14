-- NOTE: This is a sample code for Touch movement
-- Add your own TouchGui then edit the code
local Touch = {}

local uis = game:GetService'UserInputService'

local plr = game.Players.LocalPlayer
local plrGui = plr.PlayerGui

local ControlInput:{moveDir:Vector3,jump:boolean}
local movement = {dir = Vector3.zero, j = false}

local buttonPos = {
	joystick = UDim2.new(0,89,1,-120),
	jump = UDim2.new(1,-80,1,-120),
}
Touch.ButtonPos = buttonPos

local connections = table.create(4)

local gui = script:WaitForChild'TouchGui'
local joystick = gui:WaitForChild'Joystick'
local joystickMain = joystick:WaitForChild'Stick'
local jumpBtn = gui:WaitForChild'Jump'

local function EndMove()
	joystick.BackgroundTransparency = .75
	joystick.Position = buttonPos.joystick
	joystickMain.Position = UDim2.new()

	movement.dir = Vector3.zero
	ControlInput.moveDir = movement.dir

	connections.move:Disconnect()
	connections.moveend:Disconnect()
	connections.move = nil
	connections.moveend = nil
end
local function PressJoystick(input:InputObject)
	joystick.BackgroundTransparency = .4

	local size = joystickMain.AbsoluteSize.X/2
	local origin = input.Position
	connections.move = input:GetPropertyChangedSignal'Position':Connect(function()
		local pos = input.Position
		local disp = pos - origin
		local stickOffset = disp*math.min(size/disp.Magnitude,1)
		joystickMain.Position = UDim2.fromOffset(stickOffset.X,stickOffset.Y)

		movement.dir = Vector3.new(disp.X,0,disp.Y)/size
		ControlInput.moveDir = movement.dir
	end)

	joystick.Position = UDim2.fromOffset(origin.X,origin.Y)

	connections.moveend = input:GetPropertyChangedSignal'UserInputState':Connect(function()
		if input.UserInputState.Name == 'End' then
			EndMove()
		end
	end)
end

local function EndJump()
	jumpBtn.BackgroundTransparency = .75

	movement.j = false
	ControlInput.jump = movement.j

	connections.jumpend:Disconnect()
	connections.jumpend = nil
end
local function PressJump(input:InputObject)
	jumpBtn.BackgroundTransparency = .4
	movement.j = true
	ControlInput.jump = movement.j

	connections.jumpend = input:GetPropertyChangedSignal'UserInputState':Connect(function()
		if input.UserInputState.Name == 'End' then
			EndJump()
		end
	end)
end

local function InputBegan(input,gp)
	if input.UserInputType.Name ~= 'Touch' then return end

	local pos = input.Position
	local topFrame for _, v in plrGui:GetGuiObjectsAtPosition(pos.X,pos.Y) do
		if v.Active then
			topFrame = v
			break
		end
	end

	if topFrame == joystick then
		if not connections.move then
			PressJoystick(input)
		end
	elseif topFrame == jumpBtn then
		if not connections.jumpend then
			PressJump(input)
		end
	end
end

function Touch.Enable(_moveInput)
	ControlInput = _moveInput

	gui.Parent = plrGui

	connections.inputbegan = uis.InputBegan:Connect(InputBegan)
	connections.focus = uis.WindowFocused:Connect(Touch.Disable)
	connections.unfocus = uis.WindowFocusReleased:Connect(Touch.Disable)
end

function Touch.Disable(disconnect)
	if connections.moveend then
		EndMove()
	end
	if connections.jumpend then
		EndJump()
	end
	movement.dir = Vector3.zero
	movement.j = false

	ControlInput.moveDir = Vector3.zero
	ControlInput.jump = false

	if disconnect then
		gui.Parent = script
		for i, c in connections do
			connections[i] = nil
			c:Disconnect()
		end
	end
end

return Touch
