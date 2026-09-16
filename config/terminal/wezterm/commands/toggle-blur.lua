local wezterm = require("wezterm")

local command = {
    brief = "Toggle background blur",
    icon = "md_blur_on",
    action = wezterm.action_callback(function(window)
        local overrides = window:get_config_overrides() or {}
        local blur = overrides.wayland_window_background_blur

        -- La configuración base lo deja activo; si no hay override, partimos de true.
        if blur == nil then
            blur = true
        end

        overrides.wayland_window_background_blur = not blur
        window:set_config_overrides(overrides)
    end),
}

return command
