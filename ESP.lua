-- modules/ESP.lua
local Module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local ESPObjects = {}
local C4ESP = {}

local BoxColor = Color3.fromRGB(255, 255, 255)
local BoxOutlineColor = Color3.fromRGB(0, 0, 0)
local ChamsColor = Color3.fromRGB(175, 25, 255)
local ChamsOutlineColor = Color3.fromRGB(255, 255, 255)
local BombTextColor = Color3.fromRGB(255, 255, 0)
local C4HighlightColor = Color3.fromRGB(255, 0, 0)
local C4TextColor = Color3.fromRGB(255, 0, 0)

local CoreGui = game:GetService("CoreGui")
local ESPFolder = Instance.new("Folder", CoreGui)
ESPFolder.Name = "ESP_Storage"

local ChamsFolder = Instance.new("Folder", CoreGui)
ChamsFolder.Name = "Chams_Storage"

local Toggles, Options

local function WorldToScreen(position)
	local screenPoint, onScreen = Camera:WorldToViewportPoint(position)
	return Vector2.new(screenPoint.X, screenPoint.Y), onScreen, screenPoint.Z
end

local function GetCorners(character)
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return nil
	end
	
	local hrp = character.HumanoidRootPart
	local hum = character:FindFirstChildOfClass("Humanoid")
	
	if not hum then return nil end
	
	local torso = hrp.Size
	local height = hum.HipHeight + (hum.RigType == Enum.HumanoidRigType.R15 and 0.5 or 0.5)
	
	local top = hrp.Position + Vector3.new(0, height + 0.5, 0)
	local bottom = hrp.Position - Vector3.new(0, height + 0.5, 0)
	
	local corners = {
		top + Vector3.new(-torso.X, 0, -torso.Z),
		top + Vector3.new(torso.X, 0, -torso.Z),
		top + Vector3.new(-torso.X, 0, torso.Z),
		top + Vector3.new(torso.X, 0, torso.Z),
		bottom + Vector3.new(-torso.X, 0, -torso.Z),
		bottom + Vector3.new(torso.X, 0, -torso.Z),
		bottom + Vector3.new(-torso.X, 0, torso.Z),
		bottom + Vector3.new(torso.X, 0, torso.Z),
	}
	
	return corners
end

local function GetBoundingBox(corners)
	local minX, minY = math.huge, math.huge
	local maxX, maxY = -math.huge, -math.huge
	
	for _, corner in ipairs(corners) do
		local screenPos, onScreen = WorldToScreen(corner)
		if onScreen then
			minX = math.min(minX, screenPos.X)
			minY = math.min(minY, screenPos.Y)
			maxX = math.max(maxX, screenPos.X)
			maxY = math.max(maxY, screenPos.Y)
		end
	end
	
	if minX == math.huge then
		return nil
	end
	
	return {
		Position = Vector2.new(minX, minY),
		Size = Vector2.new(maxX - minX, maxY - minY)
	}
end

local function Create2DBox()
	local box = {
		Outline = Drawing.new("Square"),
		Main = Drawing.new("Square"),
	}
	
	box.Outline.Thickness = 3
	box.Outline.Filled = false
	box.Outline.Color = BoxOutlineColor
	box.Outline.Visible = false
	box.Outline.ZIndex = 1
	
	box.Main.Thickness = 1
	box.Main.Filled = false
	box.Main.Color = BoxColor
	box.Main.Visible = false
	box.Main.ZIndex = 2
	
	return box
end

local function CreateBombText()
	local text = Drawing.new("Text")
	text.Text = "HAS BOMB"
	text.Color = BombTextColor
	text.Size = 12
	text.Center = false
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false
	text.Font = 2
	text.ZIndex = 3
	
	return text
end

local function CreateHeldItemText()
	local text = Drawing.new("Text")
	text.Text = ""
	text.Color = Color3.fromRGB(255, 255, 255)
	text.Size = 13
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false
	text.Font = 2
	text.ZIndex = 3
	
	return text
end

local function CreateC4Label()
	local text = Drawing.new("Text")
	text.Text = "BOMB"
	text.Color = C4TextColor
	text.Size = 14
	text.Center = true
	text.Outline = true
	text.OutlineColor = Color3.fromRGB(0, 0, 0)
	text.Visible = false
	text.Font = 2
	text.ZIndex = 3
	
	return text
end

local function getEquippedTool(player)
	if player.Name and workspace:FindFirstChild(player.Name) then
		local equippedVal = workspace[player.Name]:FindFirstChild("EquippedTool")
		if equippedVal and equippedVal:IsA("StringValue") and equippedVal.Value ~= "" then
			return equippedVal.Value
		end
	end
	
	if player.Character then
		local tool = player.Character:FindFirstChildOfClass("Tool")
		if tool then
			return tool.Name
		end
	end
	
	return nil
end

local function isSameTeam(player)
	if not Toggles.TeamCheck or not Toggles.TeamCheck.Value then
		return false
	end
	
	if player == LocalPlayer then
		return true
	end
	
	local localPlayerObj = Players:FindFirstChild(LocalPlayer.Name)
	local otherPlayerObj = Players:FindFirstChild(player.Name)
	
	if localPlayerObj and otherPlayerObj then
		local localTeam = localPlayerObj:FindFirstChild("Status")
		local otherTeam = otherPlayerObj:FindFirstChild("Status")
		
		if localTeam and otherTeam then
			localTeam = localTeam:FindFirstChild("Team")
			otherTeam = otherTeam:FindFirstChild("Team")
			
			if localTeam and otherTeam then
				return localTeam.Value == otherTeam.Value
			end
		end
	end
	
	return false
end

local function hasBomb(player)
	local statusFolder = workspace:FindFirstChild("Status")
	if not statusFolder then return false end
	
	local hasBombValue = statusFolder:FindFirstChild("HasBomb")
	if not hasBombValue then return false end
	
	return hasBombValue.Value == player.Name
end

local function CreateESP(player)
	if player == LocalPlayer then return end
	
	local esp = {
		Player = player,
		Box = Create2DBox(),
		BombText = CreateBombText(),
		HeldItemText = CreateHeldItemText(),
		Chams = nil,
	}
	
	ESPObjects[player] = esp
	
	if Toggles.EnableChams and Toggles.EnableChams.Value then
		local highlight = Instance.new("Highlight")
		highlight.Name = player.Name
		highlight.FillColor = ChamsColor
		highlight.FillTransparency = 0.5
		highlight.OutlineColor = ChamsOutlineColor
		highlight.OutlineTransparency = 0
		highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		highlight.Parent = ChamsFolder
		
		if player.Character then
			highlight.Adornee = player.Character
		end
		
		esp.Chams = highlight
	end
end

local function RemoveESP(player)
	local esp = ESPObjects[player]
	if not esp then return end
	
	if esp.Box then
		esp.Box.Outline:Remove()
		esp.Box.Main:Remove()
	end
	
	if esp.BombText then
		esp.BombText:Remove()
	end
	
	if esp.HeldItemText then
		esp.HeldItemText:Remove()
	end
	
	if esp.Chams then
		esp.Chams:Destroy()
	end
	
	ESPObjects[player] = nil
end

local function UpdateESP()
	for player, esp in pairs(ESPObjects) do
		if not player or not player.Parent or not player.Character then
			esp.Box.Outline.Visible = false
			esp.Box.Main.Visible = false
			esp.BombText.Visible = false
			esp.HeldItemText.Visible = false
			if esp.Chams then
				esp.Chams.Enabled = false
			end
			continue
		end
		
		local character = player.Character
		local shouldShow = true
		
		if Toggles.TeamCheck and Toggles.TeamCheck.Value and isSameTeam(player) then
			shouldShow = false
		end
		
		if Toggles.EnableChams and Toggles.EnableChams.Value and shouldShow then
			if not esp.Chams or not esp.Chams.Parent then
				local highlight = Instance.new("Highlight")
				highlight.Name = player.Name
				highlight.FillColor = Options.ChamsColor and Options.ChamsColor.Value or ChamsColor
				highlight.FillTransparency = 0.5
				highlight.OutlineColor = Options.ChamsOutlineColor and Options.ChamsOutlineColor.Value or ChamsOutlineColor
				highlight.OutlineTransparency = 0
				highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
				highlight.Parent = ChamsFolder
				highlight.Adornee = character
				esp.Chams = highlight
			else
				esp.Chams.Enabled = true
				esp.Chams.Adornee = character
				esp.Chams.FillColor = Options.ChamsColor and Options.ChamsColor.Value or ChamsColor
				esp.Chams.OutlineColor = Options.ChamsOutlineColor and Options.ChamsOutlineColor.Value or ChamsOutlineColor
			end
		else
			if esp.Chams then
				esp.Chams.Enabled = false
			end
		end
		
		local corners = nil
		local box = nil
		
		if shouldShow then
			corners = GetCorners(character)
			if corners then
				box = GetBoundingBox(corners)
			end
		end
		
		if Toggles.Enable2DBox and Toggles.Enable2DBox.Value and box then
			esp.Box.Outline.Size = box.Size
			esp.Box.Outline.Position = box.Position
			esp.Box.Outline.Color = Options.BoxOutlineColor and Options.BoxOutlineColor.Value or BoxOutlineColor
			esp.Box.Outline.Visible = true
			
			esp.Box.Main.Size = box.Size
			esp.Box.Main.Position = box.Position
			esp.Box.Main.Color = Options.BoxColor and Options.BoxColor.Value or BoxColor
			esp.Box.Main.Visible = true
		else
			esp.Box.Outline.Visible = false
			esp.Box.Main.Visible = false
		end
		
		if Toggles.EnableBombESP and Toggles.EnableBombESP.Value and shouldShow and box and hasBomb(player) then
			esp.BombText.Position = Vector2.new(box.Position.X - 60, box.Position.Y + box.Size.Y / 2)
			esp.BombText.Color = Options.BombTextColor and Options.BombTextColor.Value or BombTextColor
			esp.BombText.Visible = true
		else
			esp.BombText.Visible = false
		end
		
		local equippedTool = getEquippedTool(player)
		if Toggles.EnableHeldItemESP and Toggles.EnableHeldItemESP.Value and shouldShow and box and equippedTool then
			esp.HeldItemText.Text = equippedTool
			esp.HeldItemText.Position = Vector2.new(box.Position.X + box.Size.X / 2, box.Position.Y + box.Size.Y + 2)
			esp.HeldItemText.Color = Options.HeldItemTextColor and Options.HeldItemTextColor.Value or Color3.fromRGB(255, 255, 255)
			esp.HeldItemText.Visible = true
		else
			esp.HeldItemText.Visible = false
		end
	end
end

local function CreateC4ESP(c4)
	local highlight = Instance.new("Highlight")
	highlight.Name = "C4_Highlight"
	highlight.Adornee = c4
	highlight.FillColor = C4HighlightColor
	highlight.FillTransparency = 0.3
	highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Parent = ChamsFolder
	
	local text = CreateC4Label()
	
	C4ESP = {
		Highlight = highlight,
		Text = text,
		C4 = c4
	}
end

local function UpdateC4ESP()
	if not Toggles.EnableBombESP or not Toggles.EnableBombESP.Value then
		if C4ESP.Highlight then
			C4ESP.Highlight.Enabled = false
		end
		if C4ESP.Text then
			C4ESP.Text.Visible = false
		end
		return
	end
	
	if C4ESP.C4 and C4ESP.C4.Parent then
		if C4ESP.Highlight then
			C4ESP.Highlight.Enabled = true
			C4ESP.Highlight.FillColor = Options.C4HighlightColor and Options.C4HighlightColor.Value or C4HighlightColor
		end
		
		if C4ESP.Text and C4ESP.C4:FindFirstChild("Primary") then
			local screenPos, onScreen = WorldToScreen(C4ESP.C4.Primary.Position + Vector3.new(0, 1, 0))
			if onScreen then
				C4ESP.Text.Position = screenPos
				C4ESP.Text.Color = Options.C4TextColor and Options.C4TextColor.Value or C4TextColor
				C4ESP.Text.Visible = true
			else
				C4ESP.Text.Visible = false
			end
		end
	else
		if C4ESP.Highlight then
			C4ESP.Highlight.Enabled = false
		end
		if C4ESP.Text then
			C4ESP.Text.Visible = false
		end
	end
end

local function RemoveC4ESP()
	if C4ESP.Highlight then
		C4ESP.Highlight:Destroy()
	end
	if C4ESP.Text then
		C4ESP.Text:Remove()
	end
	C4ESP = {}
end

local function MonitorC4()
	local debris = workspace:FindFirstChild("Debris")
	if not debris then
		workspace.ChildAdded:Connect(function(child)
			if child.Name == "Debris" then
				MonitorC4()
			end
		end)
		return
	end
	
	debris.ChildAdded:Connect(function(child)
		if child.Name == "C4" then
			task.wait(0.1)
			CreateC4ESP(child)
		end
	end)
	
	local c4 = debris:FindFirstChild("C4")
	if c4 then
		CreateC4ESP(c4)
	end
	
	debris.ChildRemoved:Connect(function(child)
		if child.Name == "C4" then
			RemoveC4ESP()
		end
	end)
end

local function SetupPlayer(player)
	CreateESP(player)
	
	player.CharacterAdded:Connect(function(character)
		task.wait(0.2)
		local esp = ESPObjects[player]
		if esp and esp.Chams then
			esp.Chams.Adornee = character
		end
	end)
end

function Module.Init(VisualsTab, Library, Opts, Togs)
	Toggles = Togs
	Options = Opts
	
	local VisualsLeft = VisualsTab:AddLeftGroupbox("Player ESP", "users")

	VisualsLeft:AddToggle("Enable2DBox", {
		Text = "2D Box ESP",
		Default = true,
		Tooltip = "CS:GO styled 2D box around players",
		Callback = function(Value)
			if not Value then
				for _, esp in pairs(ESPObjects) do
					esp.Box.Outline.Visible = false
					esp.Box.Main.Visible = false
				end
			end
		end,
	})

	VisualsLeft:AddLabel("Box Color"):AddColorPicker("BoxColor", {
		Default = BoxColor,
		Title = "Box Color",
		Callback = function(Value)
			BoxColor = Value
		end,
	})

	VisualsLeft:AddLabel("Box Outline Color"):AddColorPicker("BoxOutlineColor", {
		Default = BoxOutlineColor,
		Title = "Box Outline",
		Callback = function(Value)
			BoxOutlineColor = Value
		end,
	})

	VisualsLeft:AddDivider()

	VisualsLeft:AddToggle("EnableChams", {
		Text = "Chams (3D Highlight)",
		Default = true,
		Tooltip = "3D highlight through walls",
		Callback = function(Value)
			if Value then
				for player, esp in pairs(ESPObjects) do
					if not esp.Chams or not esp.Chams.Parent then
						local highlight = Instance.new("Highlight")
						highlight.Name = player.Name
						highlight.FillColor = ChamsColor
						highlight.FillTransparency = 0.5
						highlight.OutlineColor = ChamsOutlineColor
						highlight.OutlineTransparency = 0
						highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
						highlight.Parent = ChamsFolder
						
						if player.Character then
							highlight.Adornee = player.Character
						end
						
						esp.Chams = highlight
					end
				end
			else
				for _, esp in pairs(ESPObjects) do
					if esp.Chams then
						esp.Chams:Destroy()
						esp.Chams = nil
					end
				end
			end
		end,
	})

	VisualsLeft:AddLabel("Chams Fill Color"):AddColorPicker("ChamsColor", {
		Default = ChamsColor,
		Title = "Chams Color",
		Transparency = 0.5,
		Callback = function(Value)
			ChamsColor = Value
		end,
	})

	VisualsLeft:AddLabel("Chams Outline Color"):AddColorPicker("ChamsOutlineColor", {
		Default = ChamsOutlineColor,
		Title = "Chams Outline",
		Callback = function(Value)
			ChamsOutlineColor = Value
		end,
	})

	VisualsLeft:AddDivider()

	VisualsLeft:AddToggle("EnableHeldItemESP", {
		Text = "Held Item ESP",
		Default = false,
		Tooltip = "Show player's equipped tool",
	})

	VisualsLeft:AddLabel("Held Item Color"):AddColorPicker("HeldItemTextColor", {
		Default = Color3.fromRGB(255, 255, 255),
		Title = "Held Item Color",
	})

	VisualsLeft:AddDivider()

	VisualsLeft:AddToggle("TeamCheck", {
		Text = "Team Check",
		Default = true,
		Tooltip = "Don't show ESP for teammates",
		Callback = function(Value)
		end,
	})

	local VisualsRight = VisualsTab:AddRightGroupbox("Bomb ESP", "bomb")

	VisualsRight:AddToggle("EnableBombESP", {
		Text = "Enable Bomb ESP",
		Default = true,
		Tooltip = "Show who has the bomb and highlight planted C4",
	})

	VisualsRight:AddLabel("'HAS BOMB' Text Color"):AddColorPicker("BombTextColor", {
		Default = BombTextColor,
		Title = "Bomb Text Color",
		Callback = function(Value)
			BombTextColor = Value
		end,
	})

	VisualsRight:AddDivider()

	VisualsRight:AddLabel("C4 Highlight Color"):AddColorPicker("C4HighlightColor", {
		Default = C4HighlightColor,
		Title = "C4 Highlight",
		Transparency = 0.3,
		Callback = function(Value)
			C4HighlightColor = Value
		end,
	})

	VisualsRight:AddLabel("C4 'BOMB' Text Color"):AddColorPicker("C4TextColor", {
		Default = C4TextColor,
		Title = "C4 Text",
		Callback = function(Value)
			C4TextColor = Value
		end,
	})
	
	-- Setup players
	Players.PlayerAdded:Connect(SetupPlayer)
	Players.PlayerRemoving:Connect(RemoveESP)

	for _, player in ipairs(Players:GetPlayers()) do
		SetupPlayer(player)
	end

	RunService.RenderStepped:Connect(function()
		UpdateESP()
		UpdateC4ESP()
	end)

	task.spawn(function()
		local localPlayerObj = Players:FindFirstChild(LocalPlayer.Name)
		if localPlayerObj then
			local status = localPlayerObj:WaitForChild("Status", 10)
			if status then
				local team = status:WaitForChild("Team", 10)
				if team then
					team:GetPropertyChangedSignal("Value"):Connect(function()
						task.wait(0.05)
					end)
				end
			end
		end
	end)

	MonitorC4()
	
	-- Cleanup
	Library:OnUnload(function()
		for player, esp in pairs(ESPObjects) do
			RemoveESP(player)
		end
		
		RemoveC4ESP()
		
		ESPFolder:Destroy()
		ChamsFolder:Destroy()
	end)
end

return Module