-- Flavour/transparency are user preference, not code — managed by
-- `nvim-min-setup theme`, not by editing this file. See lua/config/user_settings.lua.
return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- load before anything else needs colors
  opts = function()
    local settings = require("config.user_settings").load()
    return {
      flavour = settings.theme,
      transparent_background = settings.transparent,
      show_end_of_buffer = false,
      term_colors = true,
      -- auto_integrations (default: true) detects installed plugins by name and enables
      -- their integrations for us — blink_cmp, gitsigns, mason, fzf, mini.nvim all pick
      -- themselves up. Only override what needs non-default styling.
      lsp_styles = {
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
        },
      },
    }
  end,
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
