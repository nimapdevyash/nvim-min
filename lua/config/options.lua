-- Disable providers/builtin plugins we never use — cuts startup work.
vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_node_provider = 0
vim.g.loaded_python3_provider = 0

local disabled_builtins = {
  "gzip", "matchit", "netrw", "netrwPlugin", "netrwSettings", "netrwFileHandlers",
  "tar", "tarPlugin", "zip", "zipPlugin", "tutor", "2html_plugin", "logipat",
  "rrhelper", "spellfile_plugin", "tohtml", "vimball", "vimballPlugin",
  "getscript", "getscriptPlugin",
}
for _, plugin in ipairs(disabled_builtins) do
  vim.g["loaded_" .. plugin] = 1
end

local o = vim.opt

-- UI
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.splitright = true
o.splitbelow = true
o.scrolloff = 8
o.wrap = false
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.showmode = false
-- 0 collapses the classic bottom cmdline row entirely — safe only because
-- lua/plugins/ui.lua's noice.nvim renders cmdline input and messages in
-- floating popups instead; without that plugin this would silently eat
-- every ":command" prompt, search prompt, and echo message.
o.cmdheight = 0
o.laststatus = 3
o.statusline = "%!v:lua.require'config.statusline'.render()"
o.pumheight = 10
o.conceallevel = 0

-- Editing
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.softtabstop = 2
o.smartindent = true
o.ignorecase = true
o.smartcase = true
o.mouse = "a"
o.clipboard = "unnamedplus"
o.inccommand = "split"
o.virtualedit = "block"

-- Files & undo
o.undofile = true
o.swapfile = false
o.backup = false
o.writebackup = false
o.autoread = true

-- Performance / responsiveness
o.updatetime = 200
o.timeoutlen = 400
o.redrawtime = 1500
o.ttimeoutlen = 10
o.lazyredraw = false -- keep false: breaks noice/statuscolumn redraws, not worth it
o.synmaxcol = 300

-- Completion / diagnostics UX
o.completeopt = { "menu", "menuone", "noselect" }
o.shortmess:append("c")
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded" },
})

-- Fold (treesitter-based, opened by default)
o.foldlevel = 99
o.foldlevelstart = 99
o.foldenable = true
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.fillchars:append({ fold = " ", foldopen = "-", foldclose = "+", foldsep = " " })
