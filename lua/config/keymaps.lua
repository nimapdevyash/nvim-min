-- All keybindings live in this ONE file, grouped by section below.
-- No which-key popup: search this file instead —
--   <leader>?   fuzzy-search every keymap (live, via fzf-lua, always accurate)
--   <leader>fK  grep this exact file
local map = vim.keymap.set
local silent = { silent = true }

local function d(desc)
  return { desc = desc, silent = true }
end

-- ── Keymap search (replaces which-key) ─────────────────────────────────────
map("n", "<leader>?", function() require("fzf-lua").keymaps() end, d("Search all keymaps"))
map("n", "<leader>fK", function()
  require("fzf-lua").grep({ search = "", cwd = vim.fn.stdpath("config") .. "/lua/config" })
end, d("Grep keymaps.lua / config source"))

-- ── General ─────────────────────────────────────────────────────────────────
map("n", "<Esc>", "<cmd>nohlsearch<cr>", d("Clear search highlight"))
map({ "n", "v" }, "<leader>w", "<cmd>w<cr>", d("Save file"))
map("n", "<leader>W", "<cmd>wa<cr>", d("Save all files"))
map("n", "<leader>q", "<cmd>q<cr>", d("Quit window"))
map("n", "<leader>Q", "<cmd>qa!<cr>", d("Quit all (discard changes)"))
map("i", "jk", "<Esc>", d("Exit insert mode"))
map("n", "x", '"_x', d("Delete char without yanking"))
map("v", "<", "<gv", d("Indent left, keep selection"))
map("v", ">", ">gv", d("Indent right, keep selection"))
map("v", "J", ":m '>+1<cr>gv=gv", d("Move selection down"))
map("v", "K", ":m '<-2<cr>gv=gv", d("Move selection up"))
map("n", "J", "mzJ`z", d("Join line, keep cursor position"))
map({ "n", "v" }, "<leader>y", '"+y', d("Yank to system clipboard"))
map("n", "<leader>Y", '"+Y', d("Yank line to system clipboard"))
map({ "n", "v" }, "<leader>p", '"_dP', d("Paste without overwriting register"))

-- ── Windows / splits ─────────────────────────────────────────────────────────
map("n", "<C-h>", "<C-w>h", d("Go to left window"))
map("n", "<C-j>", "<C-w>j", d("Go to lower window"))
map("n", "<C-k>", "<C-w>k", d("Go to upper window"))
map("n", "<C-l>", "<C-w>l", d("Go to right window"))
map("n", "<leader>sv", "<cmd>vsplit<cr>", d("Split window vertically"))
map("n", "<leader>sh", "<cmd>split<cr>", d("Split window horizontally"))
map("n", "<leader>se", "<C-w>=", d("Equalize window sizes"))
map("n", "<leader>sx", "<cmd>close<cr>", d("Close split"))
map("n", "<C-Up>", "<cmd>resize +2<cr>", d("Increase window height"))
map("n", "<C-Down>", "<cmd>resize -2<cr>", d("Decrease window height"))
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", d("Decrease window width"))
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", d("Increase window width"))

-- ── Buffers / tabs ───────────────────────────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<cr>", d("Next buffer"))
map("n", "<S-h>", "<cmd>bprevious<cr>", d("Previous buffer"))
map("n", "<leader>bd", "<cmd>bdelete<cr>", d("Delete buffer"))
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr>", d("Delete all other buffers"))

-- ── Find / fzf-lua ───────────────────────────────────────────────────────────
map("n", "<leader>ff", function() require("fzf-lua").files() end, d("Find files"))
map("n", "<leader>fg", function() require("fzf-lua").live_grep() end, d("Live grep in project"))
map("n", "<leader>fw", function() require("fzf-lua").grep_cword() end, d("Grep word under cursor"))
map("n", "<leader>fb", function() require("fzf-lua").buffers() end, d("Find buffers"))
map("n", "<leader>fr", function() require("fzf-lua").oldfiles() end, d("Recent files"))
map("n", "<leader>fh", function() require("fzf-lua").helptags() end, d("Help tags"))
map("n", "<leader>fd", function() require("fzf-lua").diagnostics_workspace() end, d("Workspace diagnostics"))
map("n", "<leader>fc", function() require("fzf-lua").git_commits() end, d("Git commits"))
map("n", "<leader>fs", function() require("fzf-lua").git_status() end, d("Git status (files)"))
map("n", "<leader>fR", function() require("fzf-lua").resume() end, d("Resume last picker"))

-- ── Files / oil.nvim ─────────────────────────────────────────────────────────
map("n", "-", "<cmd>Oil<cr>", d("Open parent directory (file manager)"))
map("n", "<leader>e", "<cmd>Oil<cr>", d("Open file manager"))

-- ── Diagnostics (native) ─────────────────────────────────────────────────────
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, d("Next diagnostic"))
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, d("Previous diagnostic"))
map("n", "<leader>cd", vim.diagnostic.open_float, d("Line diagnostics"))
map("n", "<leader>cq", vim.diagnostic.setloclist, d("Diagnostics to loclist"))

-- ── LSP (buffer-local maps set in lsp.lua on LspAttach; global fallbacks here)
map("n", "<leader>ci", "<cmd>LspInfo<cr>", d("LSP info"))
map("n", "<leader>cm", "<cmd>Mason<cr>", d("Mason installer UI"))

-- ── Git (gitsigns; hunk navigation, staging, blame) ─────────────────────────
map("n", "]c", function()
  if vim.wo.diff then return "]c" end
  vim.schedule(function() require("gitsigns").nav_hunk("next") end)
  return "<Ignore>"
end, { expr = true, desc = "Next git hunk" })
map("n", "[c", function()
  if vim.wo.diff then return "[c" end
  vim.schedule(function() require("gitsigns").nav_hunk("prev") end)
  return "<Ignore>"
end, { expr = true, desc = "Previous git hunk" })
map("n", "<leader>gs", function() require("gitsigns").stage_hunk() end, d("Stage hunk"))
map("v", "<leader>gs", function()
  require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
end, d("Stage selected hunk"))
map("n", "<leader>gr", function() require("gitsigns").reset_hunk() end, d("Reset hunk"))
map("n", "<leader>gp", function() require("gitsigns").preview_hunk() end, d("Preview hunk"))
map("n", "<leader>gb", function() require("gitsigns").blame_line({ full = true }) end, d("Blame line"))
map("n", "<leader>gB", function() require("gitsigns").toggle_current_line_blame() end, d("Toggle inline blame"))
map("n", "<leader>gd", function() require("gitsigns").diffthis() end, d("Diff against index"))
map("n", "<leader>gu", function() require("gitsigns").reset_buffer() end, d("Undo all hunks in buffer"))

-- ── Terminal / devops (toggleterm + lazygit) ────────────────────────────────
map("n", "<leader>gg", "<cmd>LazyGit<cr>", d("Open LazyGit"))
map("n", "<C-\\>", "<cmd>ToggleTerm direction=float<cr>", d("Toggle floating terminal"))
map("t", "<C-\\>", "<cmd>ToggleTerm<cr>", d("Toggle terminal from terminal mode"))
map("t", "<Esc>", "<C-\\><C-n>", d("Exit terminal mode"))

-- ── AI / Gemini (codecompanion) ──────────────────────────────────────────────
map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", d("AI: toggle chat"))
map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionActions<cr>", d("AI: actions palette"))
map("v", "<leader>aA", "<cmd>CodeCompanionChat Add<cr>", d("AI: add selection to chat"))
map({ "n", "v" }, "<leader>ai", ":CodeCompanion ", { desc = "AI: inline prompt (type task, <cr>)" })
map("n", "<leader>ax", "<cmd>CodeCompanionChat Toggle<cr><cmd>stopinsert<cr>", d("AI: close chat input"))
