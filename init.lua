-- nvim-min: minimal, fast Neovim config for MERN + DevOps + Gen AI
-- Switch into this config with `NVIM_APPNAME=nvim-min nvim` (see README.md)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Before anything else can call vim.notify — see lua/config/error_log.lua.
-- Superseded once noice.nvim loads (lua/config/autocmds.lua switches to a
-- different hook there, since noice replaces vim.notify wholesale).
require("config.error_log").wrap_notify()

-- API keys managed by `nvim-min-setup` (see bin/nvim-min-setup), not env vars
-- you have to remember to export yourself. Must run before plugins load.
require("config.user_settings").load_secrets()

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
