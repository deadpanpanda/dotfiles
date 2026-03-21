local wezterm = require("wezterm")
local config = {}

config.default_domain = "WSL:Ubuntu"
config.default_prog = { "fish" }
config.color_scheme = "Dracula (Official)"
config.font = wezterm.font("FiraCode Nerd Font")
config.harfbuzz_features = { "calt=1", "clig=1", "liga=1" }

return config
