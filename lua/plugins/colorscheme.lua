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

    -- onedark.nvim's own `transparent` option (lua/onedark/highlights.lua)
    -- checks `cfg.transparent` for most groups (Normal, SignColumn, ...) but
    -- hardcodes NormalFloat/FloatBorder/Pmenu* to a solid bg regardless —
    -- verified by reading the plugin's source, not assumed. Since
    -- blink.cmp/snacks.nvim/noice.nvim/native LSP hover all
    -- ultimately paint their floats through one of these groups (blink.cmp
    -- links straight to Pmenu/NormalFloat; snacks.win links Normal->NormalFloat),
    -- this single override is what actually makes every floating panel
    -- see-through against a transparent terminal, not just the main buffer.
    -- See docs/decisions/index.md#float-transparency.
    if opts.transparent then
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
      vim.api.nvim_set_hl(0, "FloatBorder", { bg = "none" })
      vim.api.nvim_set_hl(0, "Pmenu", { bg = "none" })
      vim.api.nvim_set_hl(0, "PmenuSbar", { bg = "none" })
      vim.api.nvim_set_hl(0, "PmenuThumb", { bg = "none" })
    end
  end,
}
