return {
  {
    "ibhagwan/fzf-lua",
    cmd = "FzfLua",
    keys = { "<leader>f" }, -- lazy-load on any <leader>f... mapping (defined in keymaps.lua)
    opts = {
      winopts = { height = 0.85, width = 0.85, border = "rounded" },
      fzf_colors = true,
    },
  },
  {
    "stevearc/oil.nvim",
    cmd = "Oil",
    keys = { "-", "<leader>e" },
    opts = {
      default_file_explorer = true,
      view_options = { show_hidden = true },
      columns = { "icon" },
      keymaps = {
        ["<C-h>"] = false, -- freed up for window navigation
        ["<C-l>"] = false,
      },
    },
  },
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "nvim-mini/mini.surround",
    keys = { "sa", "sd", "sr", "sf", "sF", "sh", "sn" },
    opts = {},
  },
}
