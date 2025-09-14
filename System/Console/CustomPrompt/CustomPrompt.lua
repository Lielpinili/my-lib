local prompts = game:GetService'ProximityPromptService'
local run = game:GetService'RunService'
local tween = game:GetService'TweenService'
local uis = game:GetService'UserInputService'

local mainGui = script:WaitForChild'PromptsGui'
local promptGui = mainGui:WaitForChild'Prompt'

local hoverSound = script:WaitForChild'hover'

local halfSeq = NumberSequence.new({
	NumberSequenceKeypoint.new(0,0),
	NumberSequenceKeypoint.new(.499,0),
	NumberSequenceKeypoint.new(.5,1),
	NumberSequenceKeypoint.new(1,1),
})
local fullSeq = NumberSequence.new({
	NumberSequenceKeypoint.new(0,0),
	NumberSequenceKeypoint.new(.5,0),
	NumberSequenceKeypoint.new(.501,1),
	NumberSequenceKeypoint.new(1,1),
})

----------------

mainGui.Parent = game.Players.LocalPlayer.PlayerGui

----------------

prompts.PromptShown:Connect(function(prompt, inputType)
	local promptGui = promptGui:Clone()
	local button = promptGui:WaitForChild'Button'
	local keyFrame = button:WaitForChild'KeyFrame'

	promptGui.Adornee = prompt.Parent
	promptGui.Parent = mainGui

	local tweenHold = {
		tween:Create(button.Action,TweenInfo.new(.1,0),{TextTransparency = 1}),
		tween:Create(button.Object,TweenInfo.new(.1,0),{TextTransparency = 1}),
		tween:Create(button.Bg,TweenInfo.new(.1,0),{BackgroundTransparency = .75}),
		tween:Create(keyFrame,TweenInfo.new(.1,1),{Size = UDim2.fromScale(.4,.4)})
	}
	local tweenRelease = {
		tween:Create(button.Action,TweenInfo.new(.1,0),{TextTransparency = 0}),
		tween:Create(button.Object,TweenInfo.new(.1,0),{TextTransparency = 0}),
		tween:Create(button.Bg,TweenInfo.new(.1,0),{BackgroundTransparency = 0.5}),
		tween:Create(keyFrame,TweenInfo.new(.1,1),{Size = UDim2.fromScale(.5,.5)})
	}
	local tweenTrigger = {
		tweenHold[1],
		tweenHold[2],
		tweenHold[3],
		tweenHold[4],
		tween:Create(button.Left,TweenInfo.new(.2,1),{Size = UDim2.fromScale(.5,1)}),
		tween:Create(button.Right,TweenInfo.new(.2,1),{Size = UDim2.fromScale(.5,1)})
	}
	local tweenIn = {
		tweenRelease[1],
		tweenRelease[2],
		tween:Create(button.Bg,TweenInfo.new(.1,1),{Size = UDim2.fromScale(1,1), BackgroundTransparency = .5}),
		tweenRelease[4]
	}
	local tweenOut = {
		tweenHold[1],
		tweenHold[2],
		tween:Create(button.Bg,TweenInfo.new(.1,1,0),{Size = UDim2.fromScale(0,0), BackgroundTransparency = 1}),
		tween:Create(keyFrame,TweenInfo.new(.1,1,0),{Size = UDim2.fromScale(0,0)})
	}


	hoverSound:Play()

	button.Action.Text = prompt.ActionText
	button.Object.Text = prompt.ObjectText

	if inputType.Name == 'Touch' then
		keyFrame.Touch.Visible = true
		keyFrame.Key.Visible = false

	elseif inputType.Name == 'Gamepad' then
		keyFrame.Touch.Visible = false
		keyFrame.Key.Visible = true

		local key = prompt.GamepadKeyCode.Name
		local buttonString = key:find'Button'
		if buttonString then
			keyFrame.Key.Text = key:sub(buttonString+1)
		else
			keyFrame.Key.Text = key
		end

	else
		keyFrame.Touch.Visible = false
		keyFrame.Key.Visible = true
		keyFrame.Key.Text = uis:GetStringForKeyCode(prompt.KeyboardKeyCode)
	end

	local holdValue if prompt.HoldDuration > 0 then
		holdValue = Instance.new'NumberValue'

		tweenHold[5] = tween:Create(holdValue,TweenInfo.new(prompt.HoldDuration,0),{Value = 1})
		tweenTrigger[7] = tweenHold[5]
	else
		button.Right.Circle.Visible = false

		local leftCircle = button.Left.Circle
		leftCircle.ImageTransparency = 1
		leftCircle.UIGradient.Enabled = false
		leftCircle.Parent.ClipsDescendants = false

		tweenTrigger[7] = tween:Create(leftCircle,TweenInfo.new(.1,0),{ImageTransparency = 0})
		tweenRelease[5] = tween:Create(leftCircle,TweenInfo.new(.1,0),{ImageTransparency = 1})
	end

	local c = {}
	c[1] = prompt.Triggered:Connect(function()
		button.Left.Size = UDim2.fromScale(.4,.8)
		button.Right.Size = UDim2.fromScale(.4,.8)
		for _, v in tweenTrigger do
			v:Play()
		end
	end)
	c[2] = prompt.TriggerEnded:Connect(function()
		if holdValue then
			tween:Create(holdValue,TweenInfo.new(1/3,1),{Value = 0}):Play()
		end
		for _, v in tweenRelease do
			v:Play()
		end
	end)

	local held
	c[3] = button.InputBegan:Connect(function(input)
		local inputType = input.UserInputType.Name
		if not held and (inputType == 'Touch' or inputType == 'MouseButton1') and input.UserInputState.Name ~= 'Change' then
			if prompt then
				held = true
				prompt:InputHoldBegin()
			end
		end
	end)
	c[4] = button.InputEnded:Connect(function(input)
		local inputType = input.UserInputType.Name
		if held and (inputType == 'Touch' or inputType == 'MouseButton1') then
			held = false
			if prompt then
				prompt:InputHoldEnd()
			end
		end
	end)

	if holdValue then
		c[5] = prompt.PromptButtonHoldBegan:Connect(function()
			for _, v in tweenHold do
				v:Play()
			end
		end)
		c[6] = prompt.PromptButtonHoldEnded:Connect(function()
			if holdValue then
				tween:Create(holdValue,TweenInfo.new(holdValue.Value^.5/3,1),{Value = 0}):Play()
			end
			for _, v in tweenRelease do
				v:Play()
			end
		end)

		local leftGradient = button.Left.Circle.UIGradient
		local rightGradient = button.Right.Circle.UIGradient
		c[7] = holdValue.Changed:Connect(function(v)
			local rot = v*360
			if rot > 180 then
				leftGradient.Rotation = math.clamp(rot, 180, 360)
				rightGradient.Rotation = 180
				leftGradient.Transparency = fullSeq
				rightGradient.Transparency = fullSeq
			else
				leftGradient.Rotation = 180
				rightGradient.Rotation = math.clamp(rot, 0, 180)
				leftGradient.Transparency = halfSeq
				rightGradient.Transparency = halfSeq
			end
		end)
	end

	for _, v in ipairs(tweenIn) do
		v:Play()
	end

	prompt.PromptHidden:Wait()

	for _, v in ipairs(c) do
		v:Disconnect()
	end
	for _, v in ipairs(tweenOut) do
		v:Play()
	end

	if holdValue then
		tween:Create(button.Left.Circle,TweenInfo.new(.1,0),{ImageTransparency = 1}):Play()
		tween:Create(button.Right.Circle,TweenInfo.new(.1,0),{ImageTransparency = 1}):Play()
	end
	task.wait(.1)
	promptGui:Destroy()
	if holdValue then
		holdValue:Destroy()
	end
end)

