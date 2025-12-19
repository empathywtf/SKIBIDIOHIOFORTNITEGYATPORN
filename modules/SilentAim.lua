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

-- Expanded hit part list for R6/R15
local ValidTargetParts = {
    "Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso",
    "LeftUpperArm","LeftLowerArm","LeftHand",
    "RightUpperArm","RightLowerArm","RightHand",
    "LeftUpperLeg","LeftLowerLeg","LeftFoot",
    "RightUpperLeg","RightLowerLeg","RightFoot",
    "LeftArm","RightArm","LeftLeg","RightLeg"
}

local GetPlayers = Players.GetPlayers
local WorldToScreen = Camera.WorldToScreenPoint
local GetPartsObscuringTarget = Camera.GetPartsObscuringTarget
local FindFirstChild = game.FindFirstChild
local GetMouseLocation = UserInputService.GetMouseLocation

local ExpectedArguments = {
    FindPartOnRayWithIgnoreList = {
        ArgCountRequired = 3,
        Args = {"Instance", "Ray", "table", "boolean", "boolean"}
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

-- Visible check per part
local function IsPartVisible(Part)
    local LocalCharacter = LocalPlayer.Character
    if not (Part and LocalCharacter) then return false end
    local IgnoreList = {LocalCharacter, Part.Parent}
    local PartsObscuring = Camera:GetPartsObscuringTarget({Part.Position}, IgnoreList)
    return #PartsObscuring == 0
end

-- Visible check per player
local function IsPlayerVisible(Player)
    local Character = Player.Character
    if not Character then return false end
    for _, partName in ipairs(ValidTargetParts) do
        local Part = Character:FindFirstChild(partName)
        if Part and IsPartVisible(Part) then
            return true
        end
    end
    return false
end

-- Get closest part to mouse cursor
local function getClosestPlayer()
    local MousePos = getMousePosition()
    local Closest
    local SmallestDistance = math.huge

    for _, Player in ipairs(GetPlayers(Players)) do
        if Player == LocalPlayer then continue end
        if TeamCheck and Player.Team == LocalPlayer.Team then continue end

        local Character = Player.Character
        if not Character then continue end
        local Humanoid = Character:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then continue end
        if VisibleCheck and not IsPlayerVisible(Player) then continue end

        -- Loop through all hit parts
        for _, partName in ipairs(ValidTargetParts) do
            local Part = Character:FindFirstChild(partName)
            if Part then
                local ScreenPos, OnScreen = WorldToScreen(Camera, Part.Position)
                if OnScreen then
                    local Distance = (Vector2.new(ScreenPos.X, ScreenPos.Y) - MousePos).Magnitude
                    if Distance < SmallestDistance and Distance <= FOVRadius then
                        SmallestDistance = Distance
                        Closest = Part
                    end
                end
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
	
	-- Hook for FindPartOnRayWithIgnoreList
	local oldNamecall
	oldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(...)
		local Method = getnamecallmethod()
		local Arguments = {...}
		local self = Arguments[1]
		local chance = CalculateChance(HitChance)
		
		if SilentAimEnabled and self == workspace and not checkcaller() and chance then
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
		FOVCircle.Position = getMousePosition()
		
		SilentAimEnabled = Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value or false
		HitChance = Options.HitChance and Options.HitChance.Value or 100
		TeamCheck = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value or false
		VisibleCheck = Toggles.VisibleCheck and Toggles.VisibleCheck.Value or false
		FOVRadius = Options.FOVRadius and Options.FOVRadius.Value or 200
		TargetPart = Options.HitParts and Options.HitParts.Value or "HumanoidRootPart"
	end)
end

return Module
