-- modules/UISettings.lua
local Module = {}

function Module.Init(UISettingsTab, Library, Options, Toggles, ThemeManager, SaveManager)
	local MenuGroup = UISettingsTab:AddLeftGroupbox("Menu", "wrench")

	MenuGroup:AddToggle("KeybindMenuOpen", {
		Default = Library.KeybindFrame.Visible,
		Text = "Open Keybind Menu",
		Callback = function(value)
			Library.KeybindFrame.Visible = value
		end,
	})

	MenuGroup:AddToggle("ShowCustomCursor", {
		Text = "Custom Cursor",
		Default = true,
		Callback = function(Value)
			Library.ShowCustomCursor = Value
		end,
	})

	MenuGroup:AddDivider()
	MenuGroup:AddLabel("Menu bind"):AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu keybind",
	})

	MenuGroup:AddButton("Unload", function()
		Library:Unload()
	end)

	Library.ToggleKeybind = Options.MenuKeybind
end

return Module
