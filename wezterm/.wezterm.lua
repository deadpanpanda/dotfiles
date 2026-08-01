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

config.keys = {
	{ key = "v", mods = "CTRL", action = wezterm.action.PasteFrom("Clipboard") },
	{ key = "v", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
	{ key = "v", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
}

wezterm.on("mux-is-process-stateful", function(proc)
	return false
end)

return config
