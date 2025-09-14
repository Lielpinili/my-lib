local Keyboard = {}

local uis = game:GetService'UserInputService'

local ControlInput:{moveDir:Vector3,jump:boolean}
local keybinds = {
	f = 'W',
	b = 'S',
	l = 'A',
	r = 'D',
	j = 'Space'
}

Keyboard.keybinds = keybinds

local movement = {f = 0, b = 0, l = 0, r = 0, j = false}
local function InputBegan(input,gp)
	if gp then return end

	local key = input.KeyCode.Name
	if key == keybinds.f then
		movement.f = 1
	elseif key == keybinds.b then
		movement.b = 1
	elseif key == keybinds.l then
		movement.l = 1
	elseif key == keybinds.r then
		movement.r = 1
	elseif key == keybinds.j then
		movement.j = true
	else
		return
	end
	ControlInput.moveDir = Vector3.new(movement.r - movement.l, 0, movement.b - movement.f)
	ControlInput.jump = movement.j
end

local function InputEnded(input,gp)
	local key = input.KeyCode.Name
	if key == keybinds.f then
		movement.f = 0
	elseif key == keybinds.b then
		movement.b = 0
	elseif key == keybinds.l then
		movement.l = 0
	elseif key == keybinds.r then
		movement.r = 0
	elseif key == keybinds.j then
		movement.j = false
	else
		return
	end
	ControlInput.moveDir = Vector3.new(movement.r - movement.l, 0, movement.b - movement.f)
	ControlInput.jump = movement.j
end

local connections = table.create(3)

function Keyboard.Enable(_moveInput)
	ControlInput = _moveInput

	connections[1] = uis.InputBegan:Connect(InputBegan)
	connections[2] = uis.InputEnded:Connect(InputEnded)
	connections[3] = uis.WindowFocused:Connect(Keyboard.Disable)
	connections[4] = uis.WindowFocusReleased:Connect(Keyboard.Disable)
end

function Keyboard.Disable(disconnect)
	if disconnect then
		for i, c in ipairs(connections) do
			connections[i] = nil
			c:Disconnect()
		end
	end

	movement.f = 0
	movement.b = 0
	movement.l = 0
	movement.r = 0
	movement.j = false

	ControlInput.moveDir = Vector3.zero
	ControlInput.jump = false
end

return Keyboard
