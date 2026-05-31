local wezterm = require 'wezterm'

return {
  keys = {
    {
      key = "b",
      mods = "CMD",
      action = wezterm.action.SendKey { key = "a", mods = "CTRL" },
    },
  },
  window_background_opacity = 0.92,
  term = "xterm-256color",
}
