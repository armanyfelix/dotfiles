local wezterm = require("wezterm")
-- local constants = require("constants")
local commands = require("commands")
local toggle_blur = require("commands.toggle-blur")
local config = wezterm.config_builder()

-- Font settings
config.font_size = 10
config.line_height = 1
-- config.cell_width = 1
config.font = wezterm.font("JetBrainsMono Nerd Font Propo")

-- Colors
config.colors = {
	-- El fondo de Utterly Nord en KDE Plasma (Colors:Window / cabecera activa).
	background = "#2e3440",
	cursor_bg = "white",
	cursor_border = "orange",
}

-- Apperance
-- Conserva el borde redimensionable, pero sin barra ni marco de título.
config.window_decorations = "RESIZE"
config.color_scheme = "nord"
config.hide_tab_bar_if_only_one_tab = true
config.window_padding = {
	left = 6,
	right = 6,
	top = 9,
	bottom = 0,
}
config.window_background_opacity = 0.7
config.text_background_opacity = 1
config.scrollback_lines = 30000
config.audible_bell = "Disabled"
-- Integración visual con Utterly-Nord/Kvantum en KDE Plasma Wayland.
-- El desenfoque lo aplica KWin; hay que tener activo el efecto "Desenfoque".
config.wayland_window_background_blur = true

-- config.window_background_image = constants.bg_image

-- Ctrl+Shift+Tab conserva el cambio de pestaña de WezTerm.
config.keys = {
	{
		key = "q",
		mods = "CTRL",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},
	{
		key = "F11",
		mods = "NONE",
		action = wezterm.action.ToggleFullScreen,
	},
	{
		key = "Tab",
		mods = "CTRL",
		action = wezterm.action.SendKey({ key = "Tab", mods = "CTRL" }),
	},
	{
		-- También disponible desde la paleta de comandos (Ctrl+Shift+P).
		key = "B",
		mods = "CTRL|SHIFT",
		action = toggle_blur.action,
	},
}

-- Miscellaneous
config.max_fps = 120
config.prefer_egl = true

-- Custom commands
wezterm.on("augment-command-palette", function()
	return commands
end)

return config
