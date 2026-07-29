-- nvim-min: minimal, fast Neovim config for MERN + DevOps + Gen AI
-- Switch into this config with `NVIM_APPNAME=nvim-min nvim` (see README.md)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- API keys managed by `nvim-min-setup` (see bin/nvim-min-setup), not env vars
-- you have to remember to export yourself. Must run before plugins load.
require("config.user_settings").load_secrets()

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
