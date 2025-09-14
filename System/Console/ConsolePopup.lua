local tween = game:GetService'TweenService'
local uis = game:GetService'UserInputService'

local frame = script.Parent

if not uis.KeyboardEnabled then
	frame:Destroy()
	return
end

local skip = false
frame.Parent:WaitForChild'Console':GetPropertyChangedSignal'Visible':Once(function()
	skip = true
	tween:Create(frame,TweenInfo.new(.6,Enum.EasingStyle.Back,0),{Position = UDim2.new(0.5,0,1,200)}):Play()
	task.wait(1)
	frame:Destroy()
end)


for i = 1, 10 do
	uis.InputBegan:Wait()
	task.wait(.5)
	if skip then return end
end

tween:Create(frame,TweenInfo.new(.6,Enum.EasingStyle.Back),{Position = UDim2.new(0.5,0,1,-50)}):Play()

task.wait(3)
if skip then return end
tween:Create(frame.UIGradient,TweenInfo.new(2,0),{Offset = Vector2.xAxis}):Play()
tween:Create(frame.Text.UIGradient,TweenInfo.new(2,0),{Offset = Vector2.xAxis}):Play()

task.wait(3)
if skip then return end
tween:Create(frame,TweenInfo.new(.6,Enum.EasingStyle.Back,0),{Position = UDim2.new(0.5,0,1,200)}):Play()

task.wait(1)
frame:Destroy()
