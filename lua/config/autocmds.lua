local augroup = vim.api.nvim_create_augroup
local autocmd = vim.api.nvim_create_autocmd

-- Flash on yank
autocmd("TextYankPost", {
  group = augroup("highlight_yank", { clear = true }),
  callback = function() vim.hl.on_yank({ timeout = 150 }) end,
})

-- Restore cursor to last position when reopening a file
autocmd("BufReadPost", {
  group = augroup("restore_cursor", { clear = true }),
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Keep splits equal size when the terminal/window is resized
autocmd("VimResized", {
  group = augroup("resize_splits", { clear = true }),
  command = "tabdo wincmd =",
})

-- Auto-create missing parent directories on save
autocmd("BufWritePre", {
  group = augroup("auto_mkdir", { clear = true }),
  callback = function(args)
    local dir = vim.fn.fnamemodify(args.match, ":p:h")
    if vim.fn.isdirectory(dir) == 0 then
      vim.fn.mkdir(dir, "p")
    end
  end,
})

-- Close throwaway buffers with a single `q`
autocmd("FileType", {
  group = augroup("close_with_q", { clear = true }),
  pattern = { "help", "qf", "lspinfo", "checkhealth", "man" },
  callback = function(args)
    vim.bo[args.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, silent = true })
  end,
})

-- Don't list terminal buffers, start in insert mode
autocmd("TermOpen", {
  group = augroup("terminal_open", { clear = true }),
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.cmd.startinsert()
  end,
})

-- Theme-derived highlights for the native statusline and dashboard. Applied
-- once immediately (autocmds.lua loads after colorscheme.lua, so onedark is
-- already active by this point) and again on every future :colorscheme
-- change.
local function setup_theme_highlights()
  require("config.statusline").setup_highlights()
  require("config.dashboard").setup_highlights()
end
setup_theme_highlights()
autocmd("ColorScheme", {
  group = augroup("theme_highlights", { clear = true }),
  callback = setup_theme_highlights,
})

-- Native start screen (see lua/config/dashboard.lua) — only when nvim opens
-- with no file args into an empty, unnamed, unmodified buffer (i.e. not
-- `nvim file.txt`, not restoring a session, not reading from a pipe).
autocmd("VimEnter", {
  group = augroup("dashboard_open", { clear = true }),
  callback = function()
    if vim.fn.argc() > 0 then return end
    local buf = vim.api.nvim_get_current_buf()
    if vim.api.nvim_buf_get_name(buf) ~= "" then return end
    if vim.bo[buf].modified then return end
    local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
    if #lines > 1 or lines[1] ~= "" then return end
    require("config.dashboard").open()
  end,
})

vim.api.nvim_create_user_command("Dashboard", function() require("config.dashboard").open() end, {})
