-- nvim-min: minimal, fast Neovim config for MERN + DevOps + Gen AI
-- Switch into this config with `NVIM_APPNAME=nvim-min nvim` (see README.md)

vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("config.lazy")
require("config.keymaps")
require("config.autocmds")
