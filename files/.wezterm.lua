local wezterm = require 'wezterm'

return {
  keys = {
    {
      key = "b",
      mods = "CMD",
      action = wezterm.action.SendKey { key = "a", mods = "CTRL" },
    },
  },
  term = "xterm-256color",
}
