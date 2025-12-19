-- modules/SkinChanger.lua
local Module = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LocalPlayer = Players.LocalPlayer

local CurrentSelectedWeapon = nil
local KnifeSkinFolders = {
	"Karambit",
	"Huntsman Knife",
	"Gut Knife",
	"Flip Knife",
	"Falchion Knife",
	"Falchion Classic",
	"Bayonet",
	"Crowbar",
	"Sickle",
	"Cleaver",
	"Butterfly Knife"
}

local function GetAllWeapons()
	local weapons = {}
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	
	if not weaponsFolder then
		return weapons
	end
	
	table.insert(weapons, "Knife")
	
	for _, weapon in ipairs(weaponsFolder:GetChildren()) do
		local isKnife = false
		for _, knifeName in ipairs(KnifeSkinFolders) do
			if weapon.Name == knifeName then
				isKnife = true
				break
			end
		end
		
		if not isKnife then
			table.insert(weapons, weapon.Name)
		end
	end
	
	return weapons
end

local function GetSkinsForWeapon(weaponName)
	local skins = {}
	
	if weaponName == "Knife" then
		local skinsFolder = ReplicatedStorage:FindFirstChild("Skins")
		if not skinsFolder then return skins end
		
		for _, knifeFolderName in ipairs(KnifeSkinFolders) do
			local knifeFolder = skinsFolder:FindFirstChild(knifeFolderName)
			if knifeFolder then
				for _, skinFolder in ipairs(knifeFolder:GetChildren()) do
					if skinFolder:IsA("Folder") then
						table.insert(skins, knifeFolderName .. " | " .. skinFolder.Name)
					end
				end
			end
		end
	else
		local skinsFolder = ReplicatedStorage:FindFirstChild("Skins")
		if not skinsFolder then return skins end
		
		local weaponFolder = skinsFolder:FindFirstChild(weaponName)
		if not weaponFolder then return skins end
		
		for _, skinFolder in ipairs(weaponFolder:GetChildren()) do
			if skinFolder:IsA("Folder") then
				table.insert(skins, skinFolder.Name)
			end
		end
	end
	
	return skins
end

local function ApplySkin(weaponName, skinName)
	if not LocalPlayer then return end
	
	local skinFolder = LocalPlayer:FindFirstChild("SkinFolder")
	if not skinFolder then return end
	
	if weaponName == "Knife" then
		local knifeSkin = skinName
		
		local ctFolder = skinFolder:FindFirstChild("CTFolder")
		if ctFolder then
			local ctKnife = ctFolder:FindFirstChild("CTKnife")
			if ctKnife and ctKnife:IsA("StringValue") then
				ctKnife.Value = knifeSkin
			end
		end
		
		local tFolder = skinFolder:FindFirstChild("TFolder")
		if tFolder then
			local tKnife = tFolder:FindFirstChild("TKnife")
			if tKnife and tKnife:IsA("StringValue") then
				tKnife.Value = knifeSkin
			end
		end
	else
		local ctFolder = skinFolder:FindFirstChild("CTFolder")
		if ctFolder then
			local weaponValue = ctFolder:FindFirstChild(weaponName)
			if weaponValue and weaponValue:IsA("StringValue") then
				weaponValue.Value = skinName
				return
			end
		end
		
		local tFolder = skinFolder:FindFirstChild("TFolder")
		if tFolder then
			local weaponValue = tFolder:FindFirstChild(weaponName)
			if weaponValue and weaponValue:IsA("StringValue") then
				weaponValue.Value = skinName
				return
			end
		end
	end
end

local function UpdateSkinDropdown(weaponName, Options)
	if not weaponName or weaponName == "" then return end
	
	CurrentSelectedWeapon = weaponName
	local skins = GetSkinsForWeapon(weaponName)
	
	if #skins > 0 then
		if Options.WeaponSkinDropdown then
			Options.WeaponSkinDropdown:SetValues(skins)
			Options.WeaponSkinDropdown:SetValue(skins[1])
		end
	else
		if Options.WeaponSkinDropdown then
			Options.WeaponSkinDropdown:SetValues({"No skins available"})
		end
	end
end

function Module.Init(WeaponsTab, Library, Options, Toggles)
	local WeaponsRightGroupbox = WeaponsTab:AddRightGroupbox("Skin Changer", "paintbrush")

	WeaponsRightGroupbox:AddToggle("EnableSkinChanger", {
		Text = "Enable Skin Changer",
		Default = false,
		Tooltip = "Change weapon and knife skins",
	})

	WeaponsRightGroupbox:AddDivider()

	local weaponsList = GetAllWeapons()

	WeaponsRightGroupbox:AddDropdown("WeaponSelector", {
		Values = weaponsList,
		Default = 1,
		Multi = false,
		Text = "Select Weapon",
		Tooltip = "Choose weapon to change skin",
		Callback = function(Value)
			UpdateSkinDropdown(Value, Options)
		end
	})

	WeaponsRightGroupbox:AddDropdown("WeaponSkinDropdown", {
		Values = {"Select a weapon first"},
		Default = 1,
		Multi = false,
		Text = "Select Skin",
		Tooltip = "Choose skin for selected weapon",
		Callback = function(Value)
			if CurrentSelectedWeapon and Toggles.EnableSkinChanger and Toggles.EnableSkinChanger.Value then
				ApplySkin(CurrentSelectedWeapon, Value)
			end
		end
	})

	if #weaponsList > 0 then
		task.spawn(function()
			task.wait(0.5)
			UpdateSkinDropdown(weaponsList[1], Options)
		end)
	end
end

return Module