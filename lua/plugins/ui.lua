return {
  {
    "nvim-mini/mini.icons",
    lazy = true,
    opts = {},
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
  },
  {
    "nvim-mini/mini.statusline",
    event = "VeryLazy",
    dependencies = { "nvim-mini/mini.icons" },
    opts = {
      use_icons = true,
    },
  },
}
