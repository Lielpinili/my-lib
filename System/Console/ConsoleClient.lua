local uis = game:GetService'UserInputService'
while not uis.KeyboardEnabled do task.wait(10) end

local plrs = game.Players

local frame = script.Parent
local inputBox = frame:WaitForChild'Input'
local inputLint = inputBox:WaitForChild'Lint'
local output = frame:WaitForChild'Output'
local divider = frame:WaitForChild'Divider'
local ACFrame = frame:WaitForChild'Autocomplete'

local outputText = script:WaitForChild'Output'
local ACText = script:WaitForChild'Autocomplete'

local Syntax = require(script:WaitForChild'Syntax')

local consoleRequest = game:GetService'ReplicatedStorage':WaitForChild'ConsoleRequest'

-----------------------------

local textChanged = inputBox:GetPropertyChangedSignal'Text'
local history = {}

local outputCount = 0
local function Output(type,msg)
	local outputText = outputText:Clone()
	if type == 0 then -- Normal
		
	elseif type == 1 then -- Warning
		outputText.TextColor3 = Color3.new(1,1,0)
	elseif type == 2 then -- Error
		outputText.TextColor3 = Color3.new(1,0,0)
	end
	outputText.Text = msg

	outputCount += 1
	outputText.Name = outputCount
	outputText.LayoutOrder = -outputCount
	output.Size = UDim2.new(1,-20,0,outputCount*20)
	frame.Size = UDim2.new(0.95,0,0,60+outputCount*20)

	outputText.Parent = output
end

local currentAC:{TextLabel}, selectedAC
local function SortAC(a,b)
	return a:lower() < b:lower()
end
local function ClearAC()
	currentAC, selectedAC = nil, 1
	for _, v in ACFrame:GetChildren() do
		if v:IsA('TextLabel') then
			v:Destroy()
		end
	end
	ACFrame.Size = UDim2.new()
end
local function FilterAC(argText,options)
	ClearAC()

	local textLength = #argText

	if type(options) == 'string' then
		ACFrame.Size = UDim2.new(0,#options*8,0,20)
		ACFrame.Position = UDim2.new(UDim.new(0,(inputBox.CursorPosition - textLength)*8),ACFrame.Position.Y)

		local ACText = ACText:Clone()
		ACText.Name = options
		ACText.Text = options
		ACText.Parent = ACFrame
		return
	end

	local possible = {}
	local longest = 0
	for _, v in options do
		local n = v:lower():find(argText:lower())
		if n == 1 then
			table.insert(possible,v)
			longest = math.max(#v,longest)
		end
	end
	if #possible == 0 then return end

	table.sort(possible,SortAC)

	local count = #possible
	ACFrame.Size = UDim2.new(0,longest*8,0,count*20)
	ACFrame.Position = UDim2.new(UDim.new(0,(inputBox.CursorPosition - textLength)*8),ACFrame.Position.Y)
	for i, v in possible do
		local ACText = ACText:Clone()
		ACText.Name = v
		ACText.Text = `<font color="#FFFF00">{v:sub(1,textLength)}</font>{v:sub(textLength+1)}`
		ACText.Parent = ACFrame
	end
	ACFrame[possible[1]].BackgroundTransparency = 0.9
	currentAC = possible
end
local function GetCurrentSyntax(text:string)
	local args = text:split(' ')
	local lastSyntax = Syntax
	for i = 1, #args-1 do
		if lastSyntax[1] then
			lastSyntax = lastSyntax[#args-i+1]
			if not lastSyntax then
				return false
			end
			break
		else
			lastSyntax = lastSyntax[args[i]]
			if not lastSyntax then
				return false
			end
		end
	end
	return lastSyntax[1] or lastSyntax
end
local function UpdateAC()
	local cursorCovered = inputBox.Text:sub(1,inputBox.CursorPosition-1)
	local ACList = GetCurrentSyntax(cursorCovered)
	local options = {}
	if ACList then
		local cursorArg = table.remove(cursorCovered:split(' '))
		local ACText = cursorArg

		inputBox.TextColor3 = Color3.new(1,1,1)
		if type(ACList) == 'table' then
			for s in ACList do
				table.insert(options,s)
			end
		else
			if ACList == '!plr' then
				options = {'@self'}
				for _, v in plrs:GetPlayers() do
					table.insert(options,v.Name)
				end
			elseif ACList == '!plrs' then
				if cursorArg:find'|' and not cursorArg:find'@' then
					ACText = table.remove(cursorArg:sub(1,#cursorArg):split'|')
				else
					options = {'@all','@self','@others'}
				end
				for _, v in plrs:GetPlayers() do
					table.insert(options,v.Name)
				end
			elseif ACList:sub(1,1) == '!' then
				options = `<{ACList:sub(2)}>`
			elseif ACList:find('|') then
				options = ACList:split('|')
			end
		end
		FilterAC(ACText,options)
	else
		inputBox.TextColor3 = Color3.new(1,0,0)
		ClearAC()
	end
end

local function UpdateLint()
	if true then return end
	local text = inputBox.Text
	local args = text:split(' ')
	local fontArgs = {`<font color="rgb(160,44,255)">{args[1]}</font>`}

	local lastSyntax = Syntax
	for i = 1, #args-1 do
		if not lastSyntax then
			fontArgs[i+1] = `<font color="rgb(255,0,0)">{args[i+1]}</font>`
		end
		lastSyntax = Syntax[args[i]]
		if not lastSyntax then
			fontArgs[i+1] = `<font color="rgb(255,0,0)">{args[i+1]}</font>`
		elseif lastSyntax[1] then
			for j = 1, #args-i+1 do
				local syntax = lastSyntax[j]
				local color = ''
				if syntax == '!number' then
					color = '255,161,29'
				elseif syntax == '!plr' or syntax == '!plrs' then
					color = '106,208,255'
				end
				fontArgs[i+j] = `<font color="rgb({color})">{args[i+j]}</font>`
			end
			break
		else
			fontArgs[i+1] = `<font color="rgb(118,94,255)">{args[i+1]}</font>`
		end
	end

	inputLint.Text = table.concat(fontArgs,' ')
end

local localCmds = {
	clear = function()
		for _, v in output:GetChildren() do
			if v:IsA'TextLabel' then
				v:Destroy()
			end
		end
		outputCount = 0
		output.Size = UDim2.new(1,-20,0,0)
		frame.Size = UDim2.new(0.95,0,0,60)
	end,
	clearcmds = function()
		table.clear(history)
		Output(0,'Cleared command history')
	end,
	consoleui = function(type,arg1)
		if type == 'pos' then
			if arg1 == 'top' then
				frame.AnchorPoint = Vector2.new(0.5,0)
				frame.Position = UDim2.fromScale(0.5,0.1)
				Output(0,'Positioned console at the top')
			elseif arg1 == 'bottom' then
				frame.AnchorPoint = Vector2.new(0.5,1)
				frame.Position = UDim2.fromScale(0.5,.9)
				Output(0,'Positioned console at the bottom')
			end
		elseif type == 'anchor' then
			if arg1 == 'top' then
				inputBox.Position = UDim2.new(0.5,0,0,10)
				divider.Position = UDim2.new(0.5,0,0,40)
				output.Position = UDim2.new(0.5,0,0,50)
				output.UIGrid.SortOrder = Enum.SortOrder.Name

				ACFrame.AnchorPoint = Vector2.zero
				ACFrame.Position = divider.Position
				Output(0,'Anchored the console at the top')
			elseif arg1 == 'bottom' then
				inputBox.Position = UDim2.new(0.5,0,1,-30)
				divider.Position = UDim2.new(0.5,0,1,-40)
				output.Position = UDim2.new(0.5,0,0,10)
				output.UIGrid.SortOrder = Enum.SortOrder.LayoutOrder

				ACFrame.AnchorPoint = Vector2.yAxis
				ACFrame.Position = divider.Position
				Output(0,'Anchored the console at the bottom')
			end

		elseif type == 'output' then
			
		end
	end,
	help = function(page)
		if tonumber(page) then
			local cmds = {}
			for s in Syntax do
				table.insert(cmds,s)
			end
			table.sort(cmds,SortAC)
			Output(0,`Displaying commands page {page} of {#cmds//10+1}:`)
			for i = 10*page - 9, 10*page do
				if not cmds[i] then break end
				Output(0,`•{cmds[i]}`)
			end
		else
			Output(0,`---- {divider.Version.Text} by Lielmaster ----`)
			Output(0,'A console panel used for admin commands')
			Output(0,'supported with autocomplete, syntax')
			Output(0,'highlighting, and customizable commands')
			Output(0,"Type a number after 'help' to show the list of commands")
		end
	end,
}

-----------------------------

divider.Version.Text = require(script:WaitForChild'Version')

-----------------------------

local lastEdited, lastCursorPos = '', -1
uis.InputBegan:Connect(function(input)
	if input.KeyCode.Name == 'Semicolon' and uis:IsKeyDown(Enum.KeyCode.LeftControl) and not uis:GetFocusedTextBox() then
		task.wait()
		inputBox:CaptureFocus()
		inputBox.Text = ''
		ClearAC()
		frame.Visible = true
	elseif inputBox:IsFocused() then
		local key = input.KeyCode.Name
		if not key or key == 'Escape' then return end

		if key == 'Up' then
			if currentAC then
				ACFrame[currentAC[selectedAC]].BackgroundTransparency = 1
				selectedAC = ((selectedAC-2)%#currentAC)+1
				ACFrame[currentAC[selectedAC]].BackgroundTransparency = 0.9
				return
			end

			local n = table.find(history,inputBox.Text) or 0
			if n == #history then return end
			task.wait()
			inputBox.Text = history[n+1]
			inputBox.CursorPosition = #inputBox.Text+1
		elseif key == 'Down' then
			if currentAC then
				ACFrame[currentAC[selectedAC]].BackgroundTransparency = 1
				selectedAC = (selectedAC%#currentAC)+1
				ACFrame[currentAC[selectedAC]].BackgroundTransparency = 0.9
				return
			end

			local n = table.find(history,inputBox.Text) or 0
			if n == 0 then return end
			task.wait()
			inputBox.Text = n == 1 and lastEdited or history[n-1]
			inputBox.CursorPosition = #inputBox.Text+1
		elseif key == 'Tab' then
			textChanged:Wait()
			local text = inputBox.Text

			local cursorPos = inputBox.CursorPosition - 1 -- Note: Almost every 'pos' relies on 'tab' character adding 1 to pos
			if currentAC then
				local cursorCovered = text:sub(1,cursorPos)
				local cursorArg = table.remove(cursorCovered:split(' '))
				local fullArg = text:sub(1+cursorPos-#cursorArg,text:find(' ',cursorPos))

				local beforeCursor, afterCursorPos
				if fullArg:find'|' then
					local localPos = #cursorArg
					local localArg = table.remove(cursorArg:sub(1,localPos):split'|')

					beforeCursor = text:sub(1,cursorPos-#localArg)
					afterCursorPos = fullArg:find('|', localPos)
					if afterCursorPos then
						afterCursorPos += cursorPos - #cursorArg
					end
				else
					beforeCursor = text:sub(1,cursorPos-#cursorArg)
					afterCursorPos = text:find(' ', cursorPos)
				end

				if afterCursorPos then
					local afterCursor = text:sub(afterCursorPos)
					inputBox.Text = beforeCursor .. currentAC[selectedAC] .. afterCursor
					inputBox.CursorPosition = #beforeCursor + #currentAC[selectedAC] + 1
					ClearAC()
				else
					local completedText = beforeCursor .. currentAC[selectedAC]
					if false and GetCurrentSyntax(completedText .. ' ') then
						inputBox.Text = completedText .. ' '
						inputBox.CursorPosition = #completedText + 2
						UpdateAC()
					else
						inputBox.Text = completedText
						inputBox.CursorPosition = #completedText + 1
						ClearAC()
					end
				end
				lastEdited, lastCursorPos = inputBox.Text, inputBox.CursorPosition
				UpdateLint()
				return
			else
				inputBox.Text = text:sub(1,inputBox.CursorPosition-2) .. text:sub(inputBox.CursorPosition)
				inputBox.CursorPosition = cursorPos
			end
		else
			local oldText = inputBox.Text
			task.wait()
			if inputBox.Text ~= oldText or key == 'Backspace' then
				lastEdited, lastCursorPos = inputBox.Text, inputBox.CursorPosition
				UpdateLint()
			end
		end

		if inputBox.Text == '' then
			ClearAC()
		else
			UpdateAC()
		end
	end
end)
inputBox:GetPropertyChangedSignal'CursorPosition':Connect(function()
	if uis:IsKeyDown(Enum.KeyCode.Left) or uis:IsKeyDown(Enum.KeyCode.Right) then
		lastCursorPos = inputBox.CursorPosition
	end
end)
inputBox.FocusLost:Connect(function(enter,input)
	if not enter then
		if input.KeyCode.Name == 'Escape' and currentAC then
			ClearAC()
			inputBox:CaptureFocus()
			print(lastCursorPos)
			inputBox.CursorPosition = lastCursorPos
		else
			frame.Visible = false
		end
		return
	end

	local text = inputBox.Text
	Output(0,'>'..text)
	if not table.find(history,text) then
		table.insert(history,1,text)
	end

	local args = text:split(' ')
	local cmd = table.remove(args,1)
	if localCmds[cmd] then
		localCmds[cmd](unpack(args))
	else
		consoleRequest:FireServer(text)
	end

	task.wait()
	lastEdited = ''
	inputBox.Text = ''
	inputLint.Text = ''
	inputBox:CaptureFocus()
	inputBox.CursorPosition = 1
	ClearAC()
end)

consoleRequest.OnClientEvent:Connect(function(type,arg1)
	Output(type,arg1)
end)
