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
-- Ctrl+Alt+N: Neovim on the Windows side, for Unreal work.
--
-- The default domain is WSL, so every pane is a Linux process and cannot see
-- C:\ paths the way Windows programs expect. Unreal has to run Windows-side:
-- UnrealBuildTool drives MSVC, and the Neovim talking to it must be the
-- Windows build. "local" is WezTerm's built-in Windows domain.
--
-- A new WINDOW rather than a tab, so it can sit beside the Unreal editor
-- instead of being buried in the WSL window.
--
-- Both Neovim installs share one config (C:\repos\dotfiles\nvim, symlinked to
-- ~/.config/nvim and %LOCALAPPDATA%\nvim), so this looks and behaves exactly
-- like an ordinary WSL one. Only has('win32') tells them apart.
--
-- CTRL|ALT + letter is free: WezTerm's defaults only use CTRL|ALT for pane
-- splits and resizing, which are punctuation and arrow keys.
-- ---------------------------------------------------------------------------

config.keys = {
	{ key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
	{ key = "v", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },

	{
		key = "n",
		mods = "CTRL|ALT",
		action = wezterm.action.SpawnCommandInNewWindow({
			domain = { DomainName = "local" },
			args = { "C:/Program Files/Neovim/bin/nvim.exe" },
			cwd = "C:/Users/adamr/Documents/Unreal Projects",
		}),
	},
}

wezterm.on("mux-is-process-stateful", function(proc)
	return false
end)

return config
