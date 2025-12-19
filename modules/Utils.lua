-- modules/Utils.lua
local Module = {}

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local NoSmokeEnabled = false
local NoFireEnabled = false

-- Utility function to destroy all children in a given folder
local function clearFolder(folder)
    if folder then
        for _, child in ipairs(folder:GetChildren()) do
            if child and child.Parent then
                child:Destroy()
            end
        end
    end
end

function Module.Init(MainTab, Library, Options, Toggles)
    local MainLeft = MainTab:AddLeftGroupbox("Utils", "tools")
    
    -- No Smoke Toggle
    MainLeft:AddToggle("NoSmoke", {
        Text = "No Smoke",
        Default = false,
        Tooltip = "Automatically deletes smoke objects",
    })
    
    -- No Fire Toggle
    MainLeft:AddToggle("NoFire", {
        Text = "No Fire",
        Default = false,
        Tooltip = "Automatically deletes fire objects",
    })
    
    -- Main loop
    RunService.RenderStepped:Connect(function()
        NoSmokeEnabled = Toggles.NoSmoke and Toggles.NoSmoke.Value or false
        NoFireEnabled = Toggles.NoFire and Toggles.NoFire.Value or false
        
        if NoSmokeEnabled then
            clearFolder(Workspace:FindFirstChild("Ray_Ignore") and Workspace.Ray_Ignore:FindFirstChild("Smokes"))
        end
        
        if NoFireEnabled then
            clearFolder(Workspace:FindFirstChild("Ray_Ignore") and Workspace.Ray_Ignore:FindFirstChild("Fires"))
        end
    end)
end

return Module
