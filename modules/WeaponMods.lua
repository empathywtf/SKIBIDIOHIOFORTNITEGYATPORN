-- modules/WeaponMods.lua
local Module = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local OriginalWeaponValues = {}
local ModificationsActive = {
	NoSpread = false,
	NoRecoil = false,
	AutoGun = false,
	InfiniteAmmo = false,
	InstantReload = false,
	InstantEquip = false,
	RapidFire = false
}

local function GetAllWeaponsForMods()
	local weapons = {}
	local weaponsFolder = ReplicatedStorage:FindFirstChild("Weapons")
	
	if not weaponsFolder then
		return weapons
	end
	
	for _, weapon in ipairs(weaponsFolder:GetChildren()) do
		table.insert(weapons, weapon)
	end
	
	return weapons
end

local function SaveOriginalValue(path, value)
	OriginalWeaponValues[path] = value
end

local function GetOriginalValue(path)
	return OriginalWeaponValues[path]
end

local function SetNoSpread(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			local spreadValues = {
				spread,
				spread:FindFirstChild("Crouch"),
				spread:FindFirstChild("Fire"),
				spread:FindFirstChild("InitialJump"),
				spread:FindFirstChild("Jump"),
				spread:FindFirstChild("Ladder"),
				spread:FindFirstChild("Land"),
				spread:FindFirstChild("Move"),
				spread:FindFirstChild("Stand")
			}
			
			for _, value in ipairs(spreadValues) do
				if value and value:IsA("NumberValue") then
					local path = value:GetFullName()
					if enabled then
						if not GetOriginalValue(path) then
							SaveOriginalValue(path, value.Value)
						end
						value.Value = 0
					else
						local original = GetOriginalValue(path)
						if original then
							value.Value = original
						end
					end
				end
			end
			
			local recoveryTime = spread:FindFirstChild("RecoveryTime")
			if recoveryTime then
				if recoveryTime:IsA("NumberValue") then
					local path = recoveryTime:GetFullName()
					if enabled then
						if not GetOriginalValue(path) then
							SaveOriginalValue(path, recoveryTime.Value)
						end
						recoveryTime.Value = 0
					else
						local original = GetOriginalValue(path)
						if original then
							recoveryTime.Value = original
						end
					end
				end
				
				local crouched = recoveryTime:FindFirstChild("Crouched")
				if crouched and crouched:IsA("NumberValue") then
					local path = crouched:GetFullName()
					if enabled then
						if not GetOriginalValue(path) then
							SaveOriginalValue(path, crouched.Value)
						end
						crouched.Value = 0
					else
						local original = GetOriginalValue(path)
						if original then
							crouched.Value = original
						end
					end
				end
			end
		end
	end
	
	ModificationsActive.NoSpread = enabled
end

local function SetNoRecoil(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local spread = weapon:FindFirstChild("Spread")
		if spread then
			local recoil = spread:FindFirstChild("Recoil")
			if recoil and recoil:IsA("NumberValue") then
				local path = recoil:GetFullName()
				if enabled then
					if not GetOriginalValue(path) then
						SaveOriginalValue(path, recoil.Value)
					end
					recoil.Value = 0
				else
					local original = GetOriginalValue(path)
					if original then
						recoil.Value = original
					end
				end
			end
		end
	end
	
	ModificationsActive.NoRecoil = enabled
end

local function SetAutoGun(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local auto = weapon:FindFirstChild("Auto")
		if auto and auto:IsA("BoolValue") then
			local path = auto:GetFullName()
			if enabled then
				if GetOriginalValue(path) == nil then
					SaveOriginalValue(path, auto.Value)
				end
				auto.Value = true
			else
				local original = GetOriginalValue(path)
				if original ~= nil then
					auto.Value = original
				end
			end
		end
	end
	
	ModificationsActive.AutoGun = enabled
end

local function SetInfiniteAmmo(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local ammo = weapon:FindFirstChild("Ammo")
		local storedAmmo = weapon:FindFirstChild("StoredAmmo")
		
		if ammo and ammo:IsA("NumberValue") then
			local path = ammo:GetFullName()
			if enabled then
				if not GetOriginalValue(path) then
					SaveOriginalValue(path, ammo.Value)
				end
				ammo.Value = 99999
			else
				local original = GetOriginalValue(path)
				if original then
					ammo.Value = original
				end
			end
		end
		
		if storedAmmo and storedAmmo:IsA("NumberValue") then
			local path = storedAmmo:GetFullName()
			if enabled then
				if not GetOriginalValue(path) then
					SaveOriginalValue(path, storedAmmo.Value)
				end
				storedAmmo.Value = 99999
			else
				local original = GetOriginalValue(path)
				if original then
					storedAmmo.Value = original
				end
			end
		end
	end
	
	ModificationsActive.InfiniteAmmo = enabled
end

local function SetInstantReload(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local reloadTime = weapon:FindFirstChild("ReloadTime")
		if reloadTime and reloadTime:IsA("NumberValue") then
			local path = reloadTime:GetFullName()
			if enabled then
				if not GetOriginalValue(path) then
					SaveOriginalValue(path, reloadTime.Value)
				end
				reloadTime.Value = 0
			else
				local original = GetOriginalValue(path)
				if original then
					reloadTime.Value = original
				end
			end
		end
	end
	
	ModificationsActive.InstantReload = enabled
end

local function SetInstantEquip(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local equipTime = weapon:FindFirstChild("EquipTime")
		if equipTime and equipTime:IsA("NumberValue") then
			local path = equipTime:GetFullName()
			if enabled then
				if not GetOriginalValue(path) then
					SaveOriginalValue(path, equipTime.Value)
				end
				equipTime.Value = 0
			else
				local original = GetOriginalValue(path)
				if original then
					equipTime.Value = original
				end
			end
		end
	end
	
	ModificationsActive.InstantEquip = enabled
end

local function SetRapidFire(enabled)
	local weapons = GetAllWeaponsForMods()
	
	for _, weapon in ipairs(weapons) do
		local fireRate = weapon:FindFirstChild("FireRate")
		if fireRate and fireRate:IsA("NumberValue") then
			local path = fireRate:GetFullName()
			if enabled then
				if not GetOriginalValue(path) then
					SaveOriginalValue(path, fireRate.Value)
				end
				fireRate.Value = 0
			else
				local original = GetOriginalValue(path)
				if original then
					fireRate.Value = original
				end
			end
		end
	end
	
	ModificationsActive.RapidFire = enabled
end

function Module.Init(WeaponsTab, Library, Options, Toggles)
	local WeaponsLeft = WeaponsTab:AddLeftGroupbox("Modifications", "wrench")

	WeaponsLeft:AddToggle("NoSpread", {
		Text = "No Spread",
		Default = false,
		Tooltip = "Remove weapon spread",
		Callback = function(Value)
			SetNoSpread(Value)
		end,
	})

	WeaponsLeft:AddToggle("NoRecoil", {
		Text = "No Recoil",
		Default = false,
		Tooltip = "Remove weapon recoil",
		Callback = function(Value)
			SetNoRecoil(Value)
		end,
	})

	WeaponsLeft:AddToggle("AutoGun", {
		Text = "Auto Every Gun",
		Default = false,
		Tooltip = "Make all guns fully automatic",
		Callback = function(Value)
			SetAutoGun(Value)
		end,
	})

	WeaponsLeft:AddToggle("InfiniteAmmo", {
		Text = "Infinite Ammo",
		Default = false,
		Tooltip = "Unlimited ammunition",
		Callback = function(Value)
			SetInfiniteAmmo(Value)
		end,
	})

	WeaponsLeft:AddToggle("InstantReload", {
		Text = "Instant Reload",
		Default = false,
		Tooltip = "Reload instantly",
		Callback = function(Value)
			SetInstantReload(Value)
		end,
	})

	WeaponsLeft:AddToggle("InstantEquip", {
		Text = "Instant Equip",
		Default = false,
		Tooltip = "Equip weapons instantly",
		Callback = function(Value)
			SetInstantEquip(Value)
		end,
	})

	WeaponsLeft:AddToggle("RapidFire", {
		Text = "Rapid Fire",
		Default = false,
		Tooltip = "Shoot at maximum speed",
		Callback = function(Value)
			SetRapidFire(Value)
		end,
	})
end

return Module
