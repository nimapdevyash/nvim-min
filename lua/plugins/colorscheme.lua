-- Style/transparency are user preference, not code — managed by
-- `nvim-min-setup theme`, not by editing this file. See lua/config/user_settings.lua.
local VALID_STYLES = {
  dark = true, darker = true, cool = true, deep = true, warm = true, warmer = true, light = true,
}

return {
  "navarasu/onedark.nvim",
  priority = 1000, -- load before anything else needs colors
  opts = function()
    local settings = require("config.user_settings").load()
    -- Guards against a settings.json written by nvim-min-setup before this
    -- config switched from catppuccin (flavour names like "mocha") to
    -- onedark (style names like "dark") — an unrecognized value would
    -- otherwise get passed straight through to onedark and break silently.
    local style = VALID_STYLES[settings.theme] and settings.theme or "dark"
    return {
      style = style,
      transparent = settings.transparent,
      term_colors = true,
      code_style = {
        comments = "italic",
      },
      diagnostics = {
        darker = true,
        undercurl = true,
        background = true,
      },
    }
  end,
  config = function(_, opts)
    require("onedark").setup(opts)
    vim.cmd.colorscheme("onedark")
  end,
}
