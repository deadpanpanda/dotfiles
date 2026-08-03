local wezterm = require("wezterm")
local config = {}

config.default_domain = "WSL:Ubuntu"

-- Top-level default_prog is ignored when the default domain is WSL,
-- so the tmux launch has to live on the WSL domain itself.
config.wsl_domains = {
	{
		name = "WSL:Ubuntu",
		distribution = "Ubuntu",
		default_cwd = "~",
		default_prog = { "tmux", "new-session" },
	},
}
config.color_scheme = "Dracula (Official)"
config.font = wezterm.font("FiraCode Nerd Font")
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }
config.window_close_confirmation = "NeverPrompt"
config.front_end = "Software"
config.webgpu_power_preference = "LowPower"
config.audible_bell = "Disabled"

-- ---------------------------------------------------------------------------
-- Windows-side tabs.
--
-- The default domain is WSL, so every tab is a Linux process and cannot see
-- C:\ paths as Windows programs expect them. Unreal work has to run on the
-- Windows side: UnrealBuildTool drives MSVC, and the Neovim that talks to it
-- must be the Windows build. "local" is WezTerm's built-in Windows domain.
--
-- Both Neovim installs share one config (C:\repos\dotfiles\nvim, symlinked
-- into ~/.config/nvim and %LOCALAPPDATA%\nvim), so a Windows tab looks and
-- behaves exactly like the WSL one.
-- ---------------------------------------------------------------------------

local windows = { DomainName = "local" }
local win_nvim = "C:/Program Files/Neovim/bin/nvim.exe"
local unreal_projects = "C:/Users/adamr/Documents/Unreal Projects"

-- New WINDOW rather than new tab: a Windows tab buried in the WSL window
-- cannot be arranged alongside the Unreal editor, which is the whole point of
-- having it. Tabs keep you inside one window; windows can be tiled.
local function windows_window(args, cwd)
	return wezterm.action.SpawnCommandInNewWindow({
		domain = windows,
		args = args,
		cwd = cwd,
	})
end

config.launch_menu = {
	{
		label = "Neovim (Windows) - Unreal Projects",
		domain = windows,
		args = { win_nvim },
		cwd = unreal_projects,
	},
	{
		label = "PowerShell (Windows)",
		domain = windows,
		args = { "powershell.exe", "-NoLogo" },
	},
	{
		label = "PowerShell (Windows) - Unreal Projects",
		domain = windows,
		args = { "powershell.exe", "-NoLogo" },
		cwd = unreal_projects,
	},
}

config.keys = {
	{ key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
	{ key = "v", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },

	-- Windows-side windows. CTRL|ALT + letter is unused by WezTerm's defaults,
	-- which only bind CTRL|ALT for pane splits and resizing (punctuation and
	-- arrows).
	{ key = "n", mods = "CTRL|ALT", action = windows_window({ win_nvim }, unreal_projects) },
	{ key = "p", mods = "CTRL|ALT", action = windows_window({ "powershell.exe", "-NoLogo" }, unreal_projects) },
	{
		key = "l",
		mods = "CTRL|ALT",
		action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|LAUNCH_MENU_ITEMS" }),
	},
}

wezterm.on("mux-is-process-stateful", function(proc)
	return false
end)

return config
