-- Pull in the wezterm API
local wezterm = require "wezterm"

-- This table will hold the configuration
config = wezterm.config_builder()

-- Enable auto reload
config.automatically_reload_config = true


-- Appearance
config.font = wezterm.font { family = "UDEV Gothic 35NFLG", weight = "Bold" }
config.font_size = 13.5

-- Appearance > Tab
config.window_decorations = "RESIZE | INTEGRATED_BUTTONS" 
local SOLID_LEFT_ARROW = wezterm.nerdfonts.ple_lower_right_triangle
local SOLID_RIGHT_ARROW = wezterm.nerdfonts.ple_upper_left_triangle
config.colors = {
  tab_bar = {
    inactive_tab_edge = "none",
  },
}
wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
  local background = "#5c6d74"
  local foreground = "#FFFFFF"
  local edge_background = "none"
  if tab.is_active then
    background = "#ae8b2d"
    foreground = "#FFFFFF"
  end
  local edge_foreground = background

  local title = "  " .. wezterm.truncate_right(tab.active_pane.title, max_width - 1) .. "  "

  return {
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_LEFT_ARROW },
    { Background = { Color = background } },
    { Foreground = { Color = foreground } },
    { Text = title },
    { Background = { Color = edge_background } },
    { Foreground = { Color = edge_foreground } },
    { Text = SOLID_RIGHT_ARROW },
  }
end)

-- Appearance > Background
config.window_background_opacity = 0.95
config.window_background_gradient = {
  -- Based on the color of the active tab `#ae8b2d`
  colors = { "#020200", "#392A00" , "#ae8b2d"},
  orientation = {
    Radial = {
      -- X and y coordinate of the center of the circle. Range=[0.0, 1.0]
      cx = 0.25,
      cy = 0.25,
      -- Specifies the radius of the notional circle.
      radius = 1.50,
    },
  },
}

-- Overwrite the background with the image if "/dotfiles/bg-image.png" exists.
local home = os.getenv("HOME")
local bg_image_path = home .. "/dotfiles/bg-image.png"
config.background = {
  {
    source = {
      File = bg_image_path,
    },
    width = "Cover",
    height = "Cover",
    horizontal_align = "Center",
    vertical_align = "Top",
  },
}

-- Key bindings
config.keys = {
  -- Make Option-Left equivalent to Alt-b which many line editors interpret as backward-word
  {key="LeftArrow", mods="OPT", action=wezterm.action{SendString="\x1bb"}},
  -- Make Option-Right equivalent to Alt-f; forward-word
  {key="RightArrow", mods="OPT", action=wezterm.action{SendString="\x1bf"}},
}

-- and finally, return the configuration to wezterm
return config
