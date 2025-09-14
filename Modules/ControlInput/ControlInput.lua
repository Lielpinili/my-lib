local ControlInput = {}

local uis = game:GetService'UserInputService'

ControlInput.moveDir = Vector3.zero
ControlInput.jump = false

local Touch = require(script:WaitForChild'Touch')
local Keyboard = require(script:WaitForChild'Keyboard')
local activeController = uis.TouchEnabled and Touch or Keyboard

activeController.Enable(ControlInput)
uis.LastInputTypeChanged:Connect(function(inputType)
	local newController = inputType.Name == 'Touch' and Touch or Keyboard
	if newController == activeController then return end

	activeController.Disable(true)
	newController.Enable(ControlInput)
	ControlInput._controller = newController

	activeController = newController
end)

uis.WindowFocusReleased:Connect(function()
	activeController.Disable()
end)

return ControlInput
