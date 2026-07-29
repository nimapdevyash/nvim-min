return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000, -- load before anything else needs colors
  opts = {
    flavour = "mocha",
    transparent_background = true,
    show_end_of_buffer = false,
    term_colors = true,
    integrations = {
      cmp = false, -- using blink.cmp instead
      blink_cmp = true,
      gitsigns = true,
      treesitter = true,
      native_lsp = {
        enabled = true,
        virtual_text = {
          errors = { "italic" },
          hints = { "italic" },
          warnings = { "italic" },
          information = { "italic" },
        },
      },
      mason = true,
      fzf = true,
      which_key = false,
    },
  },
  config = function(_, opts)
    require("catppuccin").setup(opts)
    vim.cmd.colorscheme("catppuccin")
  end,
}
