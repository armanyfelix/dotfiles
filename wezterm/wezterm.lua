local wezterm = require("wezterm")
-- local constants = require("constants")
local config = wezterm.config_builder()

-- Font settings
config.font_size = 15
config.line_height = 1.2
config.cell_width = 1
config.font = wezterm.font "Iosevka Term Nerd Font"

-- Colors
config.colors = {
  cursor_bg = "white",
  cursor_border = "orange",
}

-- Apperance
-- config.window_decorations = "RESIZE"
config.color_scheme = "Firewatch"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
  left = 0,
  right = 0,
  top = 0,
  bottom = 0,
}
config.window_background_opacity = 0.85
config.text_background_opacity = 0.9
-- config.window_background_image = constants.bg_image

return config
