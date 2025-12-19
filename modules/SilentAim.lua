-- modules/SilentAim.lua
local Module = {}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local SilentAimEnabled = false
local HitChance = 100
local TeamCheck = false
local VisibleCheck = true
local TargetPart = "HumanoidRootPart"
local FOVRadius = 200

-- Expanded list of all standard R6 & R15 humanoid parts
local ValidTargetParts = {
	"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Torso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot",
	"LeftArm", "RightArm", "LeftLeg", "RightLeg",
}

local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local FindFirstChild = game.FindFirstChild
local GetMouseLocation = UserInputService.GetMouseLocation

local ExpectedArguments = {
	FindPartOnRayWithIgnoreList = {
		ArgCountRequired = 3,
		Args = {
			"Instance",
			"Ray",
			"table",
			"boolean",
			"boolean"
		}
	}
}

function CalculateChance(Percentage)
	Percentage = math.floor(Percentage)
	local chance = math.floor(Random.new().NextNumber(Random.new(), 0, 1) * 100) / 100
	return chance <= Percentage / 100
end

local function getPositionOnScreen(Vector)
	local Vec3, OnScreen = WorldToScreen(Camera, Vector)
	return Vector2.new(Vec3.X, Vec3.Y), OnScreen
end

local function ValidateArguments(Args, RayMethod)
	local Matches = 0
	if #Args < RayMethod.ArgCountRequired then
		return false
	end
	
	for Pos, Argument in next, Args do
		if typeof(Argument) == RayMethod.Args[Pos] then
			Matches = Matches + 1
		end
	end
	
	return Matches >= RayMethod.ArgCountRequired
end

local function getDirection(Origin, Position)
	return (Position - Origin).Unit * 1000
end

local function getMousePosition()
	return GetMouseLocation(UserInputService)
end

local function IsPlayerVisible(Player, TargetPartToCheck)
	local PlayerCharacter = Player.Character
	local LocalPlayerCharacter = LocalPlayer.Character
	
	if not (PlayerCharacter and LocalPlayerCharacter) then
		return false
	end
	
	-- Use the specific part we're checking, not the global TargetPart
	local PlayerPart = TargetPartToCheck or FindFirstChild(PlayerCharacter, "HumanoidRootPart")
	
	if not PlayerPart then
		return false
	end
	
	-- Get camera position
	local CameraPosition = Camera.CFrame.Position
	local PartPosition = PlayerPart.Position
	
	-- Create a ray from camera to the target part
	local Direction = (PartPosition - CameraPosition)
	local Distance = Direction.Magnitude
	local Ray = Ray.new(CameraPosition, Direction.Unit * Distance)
	
	-- Ignore list should include both characters
	local IgnoreList = {LocalPlayerCharacter, PlayerCharacter}
	
	-- Cast the ray
	local Hit, Position = workspace:FindPartOnRayWithIgnoreList(Ray, IgnoreList, false, true)
	
	-- If nothing was hit, the player is visible
	-- If something was hit, check if it's part of the target character
	if not Hit then
		return true
	end
	
	-- Check if the hit part belongs to the target character
	local HitParent = Hit.Parent
	while HitParent do
		if HitParent == PlayerCharacter then
			return true
		end
		HitParent = HitParent.Parent
	end
	
	return false
end

local function getClosestPlayer()
	if not TargetPart then return end
	
	local Closest
	local DistanceToMouse
	local MousePos = getMousePosition()
	
	for _, Player in next, GetPlayers(Players) do
		if Player == LocalPlayer then continue end
		if TeamCheck and Player.Team == LocalPlayer.Team then continue end
		
		local Character = Player.Character
		if not Character then continue end
		
		local HumanoidRootPart = FindFirstChild(Character, "HumanoidRootPart")
		local Humanoid = FindFirstChild(Character, "Humanoid")
		
		if not HumanoidRootPart or not Humanoid or Humanoid.Health <= 0 then
			continue
		end
		
		local ScreenPosition, OnScreen = getPositionOnScreen(HumanoidRootPart.Position)
		if not OnScreen then continue end
		
		local Distance = (MousePos - ScreenPosition).Magnitude
		
		if Distance <= (DistanceToMouse or FOVRadius or 2000) then
			local targetPartToUse = nil
			
			if TargetPart == "Closest" then
				local closestPart = nil
				local closestDistance = math.huge
				
				for _, partName in ipairs(ValidTargetParts) do
					local part = FindFirstChild(Character, partName)
					if part then
						local partScreenPos, partOnScreen = getPositionOnScreen(part.Position)
						if partOnScreen then
							local partDistance = (MousePos - partScreenPos).Magnitude
							if partDistance < closestDistance then
								closestDistance = partDistance
								closestPart = part
							end
						end
					end
				end
				
				targetPartToUse = closestPart
			elseif TargetPart == "Random" then
				local availableParts = {}
				for _, partName in ipairs(ValidTargetParts) do
					local part = FindFirstChild(Character, partName)
					if part then
						table.insert(availableParts, part)
					end
				end
				
				if #availableParts > 0 then
					targetPartToUse = availableParts[math.random(1, #availableParts)]
				end
			else
				targetPartToUse = FindFirstChild(Character, TargetPart)
			end
			
			-- Check visibility for the specific part we're targeting
			if VisibleCheck and targetPartToUse and not IsPlayerVisible(Player, targetPartToUse) then
				continue
			end
			
			if targetPartToUse then
				Closest = targetPartToUse
				DistanceToMouse = Distance
			end
		end
	end
	
	return Closest
end

function Module.Init(MainTab, Library, Options, Toggles)
	local MainLeft = MainTab:AddLeftGroupbox("Silent Aim", "crosshair")
	local MainRight = MainTab:AddRightGroupbox("Checks", "check")
	
	MainLeft:AddToggle("SilentAimEnabled", {
		Text = "Silent Aim",
		Default = false,
		Tooltip = "Redirects bullets to target",
	})
	
	MainLeft:AddSlider("HitChance", {
		Text = "Hit Chance",
		Default = 100,
		Min = 0,
		Max = 100,
		Rounding = 0,
		Suffix = "%",
	})
	
	MainLeft:AddDropdown("HitParts", {
		Values = {"Head", "HumanoidRootPart", "UpperTorso", "LowerTorso", "Closest", "Random"},
		Default = 2,
		Multi = false,
		Text = "Hit Part",
		Tooltip = "Select part to target",
	})
	
	MainLeft:AddToggle("VisibleFOV", {
		Text = "Visible FOV",
		Default = false,
	})
	
	MainLeft:AddSlider("FOVRadius", {
		Text = "FOV Radius",
		Default = 200,
		Min = 0,
		Max = 1000,
		Rounding = 0,
	})
	
	MainRight:AddToggle("VisibleCheck", {
		Text = "Visible Check",
		Default = true,
	})
	
	MainRight:AddToggle("SilentAimTeamCheck", {
		Text = "Team Check",
		Default = false,
	})
	
	-- Hook
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
		local Method = getnamecallmethod()
		local Arguments = {...}
		local self = Arguments[1]
		local chance = CalculateChance(HitChance)
		
		if SilentAimEnabled and self == workspace and not checkcaller() and chance == true then
			if Method == "FindPartOnRayWithIgnoreList" then
				if ValidateArguments(Arguments, ExpectedArguments.FindPartOnRayWithIgnoreList) then
					local A_Ray = Arguments[2]
					local HitPart = getClosestPlayer()
					
					if HitPart then
						local Origin = A_Ray.Origin
						local Direction = getDirection(Origin, HitPart.Position)
						Arguments[2] = Ray.new(Origin, Direction)
						
						return oldNamecall(unpack(Arguments))
					end
				end
			end
		end
		
		return oldNamecall(...)
	end))
	
	-- FOV Circle
	local FOVCircle = Drawing.new("Circle")
	FOVCircle.Color = Color3.fromRGB(255, 255, 255)
	FOVCircle.Thickness = 1
	FOVCircle.NumSides = 60
	FOVCircle.Filled = false
	FOVCircle.Transparency = 1
	FOVCircle.Visible = false
	FOVCircle.Radius = 200
	
	RunService.RenderStepped:Connect(function()
		FOVCircle.Visible = Toggles.VisibleFOV and Toggles.VisibleFOV.Value or false
		FOVCircle.Radius = Options.FOVRadius and Options.FOVRadius.Value or 200
		FOVCircle.Position = GetMouseLocation(UserInputService)
		
		SilentAimEnabled = Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value or false
		HitChance = Options.HitChance and Options.HitChance.Value or 100
		TeamCheck = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value or false
		VisibleCheck = Toggles.VisibleCheck and Toggles.VisibleCheck.Value or false
		FOVRadius = Options.FOVRadius and Options.FOVRadius.Value or 200
		TargetPart = Options.HitParts and Options.HitParts.Value or "HumanoidRootPart"
	end)
end

return Module
