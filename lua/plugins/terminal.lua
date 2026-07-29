return {
  "akinsho/toggleterm.nvim",
  cmd = { "ToggleTerm", "LazyGit" },
  keys = { "<C-\\>", "<leader>gg" },
  opts = {
    open_mapping = [[<c-\>]],
    direction = "float",
    float_opts = { border = "curved" },
    shading_factor = 2,
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)

    local Terminal = require("toggleterm.terminal").Terminal
    local lazygit = Terminal:new({
      cmd = "lazygit",
      hidden = true,
      direction = "float",
      float_opts = { border = "curved" },
      on_open = function(term) vim.cmd("startinsert!") end,
    })

    vim.api.nvim_create_user_command("LazyGit", function() lazygit:toggle() end, {})
  end,
}
