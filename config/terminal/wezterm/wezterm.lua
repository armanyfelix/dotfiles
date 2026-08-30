local wezterm = require("wezterm")
local commands = require("commands")
local config = wezterm.config_builder()

config.font_size = 13
config.line_height = 1.2
config.cell_width = 1
config.font = wezterm.font "Iosevka Term Nerd Font"

config.colors = {
    cursor_bg = "white",
    cursor_border = "orange",
}

config.color_scheme = "nordfox"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
}
config.window_background_opacity = 0.8
config.text_background_opacity = 0.9

config.max_fps = 120
config.prefer_egl = true

wezterm.on("augment-command-palette", function()
    return commands
end)

return config
