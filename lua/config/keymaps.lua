-- All keybindings live in this ONE file, grouped by section below.
-- No which-key popup: search this file instead —
--   <leader>?   fuzzy-search every keymap (key + description only, see keymap_search.lua)
--   <leader>fK  grep this exact file
local map = vim.keymap.set

local function d(desc)
  return { desc = desc, silent = true }
end

-- Read once at startup; toggling this persistently is `nvim-min-setup features`
-- (controls whether minuet-ai.nvim even loads). <leader>at below is a
-- separate, session-only on/off switch for when the plugin IS loaded.
local ghost_text_enabled = require("config.user_settings").load().features.ghost_text

-- ── Keymap search (replaces which-key) ─────────────────────────────────────
map("n", "<leader>?", function() require("config.keymap_search").picker() end, d("Search all keymaps"))
map("n", "<leader>fK", function()
  require("snacks").picker.grep({ cwd = vim.fn.stdpath("config") .. "/lua/config" })
end, d("Grep keymaps.lua / config source"))

-- ── General ─────────────────────────────────────────────────────────────────
map("n", "<leader>h", "<cmd>Dashboard<cr>", d("Open the start screen"))
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
-- Same resizes, hjkl-shaped (needs a terminal that distinguishes Ctrl+Shift
-- from Ctrl — kitty does, via its keyboard protocol)
map("n", "<C-S-h>", "<cmd>vertical resize -2<cr>", d("Shrink window width"))
map("n", "<C-S-l>", "<cmd>vertical resize +2<cr>", d("Grow window width"))
map("n", "<C-S-j>", "<cmd>resize -2<cr>", d("Shrink window height"))
map("n", "<C-S-k>", "<cmd>resize +2<cr>", d("Grow window height"))

-- ── Buffers / tabs ───────────────────────────────────────────────────────────
map("n", "<S-l>", "<cmd>bnext<cr>", d("Next buffer"))
map("n", "<S-h>", "<cmd>bprevious<cr>", d("Previous buffer"))
map("n", "<leader>bd", "<cmd>bdelete<cr>", d("Delete buffer"))
map("n", "<leader>bo", "<cmd>%bd|e#|bd#<cr>", d("Delete all other buffers"))

-- ── Find / snacks.picker ─────────────────────────────────────────────────────
map("n", "<leader>ff", function() require("snacks").picker.files() end, d("Find files"))
map("n", "<leader>fg", function() require("snacks").picker.grep() end, d("Live grep in project"))
map("n", "<leader>fw", function() require("snacks").picker.grep_word() end, d("Grep word under cursor"))
map("n", "<leader>fb", function() require("snacks").picker.buffers() end, d("Find buffers"))
map("n", "<leader>fr", function() require("snacks").picker.recent() end, d("Recent files"))
map("n", "<leader>fh", function() require("snacks").picker.help() end, d("Help tags"))
map("n", "<leader>fd", function() require("snacks").picker.diagnostics() end, d("Workspace diagnostics"))
map("n", "<leader>fc", function() require("snacks").picker.git_log() end, d("Git commits"))
map("n", "<leader>fs", function() require("snacks").picker.git_status() end, d("Git status (files)"))
map("n", "<leader>fR", function() require("snacks").picker.resume() end, d("Resume last picker"))

-- ── Files / snacks explorer ──────────────────────────────────────────────────
map("n", "-", function() require("snacks").explorer() end, d("Open file explorer"))
map("n", "<leader>e", function() require("snacks").explorer() end, d("Open file explorer"))

-- ── Diagnostics (native) ─────────────────────────────────────────────────────
map("n", "]d", function() vim.diagnostic.jump({ count = 1, float = true }) end, d("Next diagnostic"))
map("n", "[d", function() vim.diagnostic.jump({ count = -1, float = true }) end, d("Previous diagnostic"))
map("n", "<leader>cd", vim.diagnostic.open_float, d("Line diagnostics"))
map("n", "<leader>cq", vim.diagnostic.setloclist, d("Diagnostics to loclist"))

-- ── LSP (buffer-local maps set in lsp.lua on LspAttach; global fallbacks here)
map("n", "<leader>ci", "<cmd>LspInfo<cr>", d("LSP info"))
map("n", "<leader>cm", "<cmd>Mason<cr>", d("Mason installer UI"))
map("n", "<leader>ch", function()
  vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, d("Toggle inlay hints (off by default — real cost on big files)"))

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

-- ── Terminal / devops (native floating terminal, see lua/config/terminal.lua)
map("n", "<leader>gg", function() require("config.terminal").toggle_lazygit() end, d("Open LazyGit"))
map({ "n", "t" }, "<C-\\>", function() require("config.terminal").toggle_terminal() end, d("Toggle floating terminal"))
map("t", "<Esc>", "<C-\\><C-n>", d("Exit terminal mode"))

-- ── AI / Gemini (codecompanion) ──────────────────────────────────────────────
map({ "n", "v" }, "<leader>aa", "<cmd>CodeCompanionChat Toggle<cr>", d("AI: toggle chat"))
map({ "n", "v" }, "<leader>ac", "<cmd>CodeCompanionActions<cr>", d("AI: actions palette"))
map("v", "<leader>aA", "<cmd>CodeCompanionChat Add<cr>", d("AI: add selection to chat"))
map({ "n", "v" }, "<leader>ai", ":CodeCompanion ", { desc = "AI: inline prompt (type task, <cr>)" })
map("n", "<leader>ax", "<cmd>CodeCompanionChat Toggle<cr><cmd>stopinsert<cr>", d("AI: close chat input"))

-- <Tab>/<CR> accept blink.cmp's completion, then fall through to snippet-jump,
-- ghost text (minuet-ai), or a normal Tab/Enter. This duplicates what
-- completion.lua's blink.cmp `keymap` preset would otherwise do — see
-- docs/decisions/index.md#blink-expr-mapping-bug for why: blink's own
-- built-in mapping is an *expr* mapping (Neovim evaluates those under
-- `textlock`), and `require('blink.cmp').is_visible()` reliably reads back
-- stale/false specifically inside that restricted evaluation context, even
-- though the exact same call from a plain (non-expr) callback — as done
-- here — reads correctly. `completion.lua` sets `["<Tab>"] = false` and
-- `["<CR>"] = false` in blink's own keymap config so the two mappings never
-- fight over the same key.
local function accept_or_fallback(key)
  local ok, cmp = pcall(require, "blink.cmp")
  if ok then
    if cmp.snippet_active() and cmp.accept() then
      return
    elseif cmp.is_visible() and cmp.select_and_accept() then
      return
    elseif key == "<Tab>" and cmp.snippet_forward() then
      return
    end
  end
  if key == "<Tab>" and ghost_text_enabled then
    local mok, minuet = pcall(require, "minuet.virtualtext")
    if mok and minuet.action.is_visible() then
      minuet.action.accept()
      return
    end
  end
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), "n", false)
end

map("i", "<Tab>", function() accept_or_fallback("<Tab>") end,
  { silent = true, desc = "Accept completion / snippet-jump / ghost text (else normal Tab)" })
map("i", "<CR>", function() accept_or_fallback("<CR>") end,
  { silent = true, desc = "Accept completion (else normal Enter)" })

map("n", "<leader>at", "<cmd>Minuet virtualtext toggle<cr>", d("AI: toggle ghost text (this session only)"))

-- ── Open externally (images, SVGs, PDFs — outsourced, no viewer plugin) ─────
map("n", "<leader>ox", function() require("config.external").open_externally() end,
  d("Open file under cursor in the OS default app"))
map("n", "<leader>oi", function() require("config.external").preview_in_terminal() end,
  d("Preview image/SVG inline (kitten icat, else OS default app)"))

-- ── Harpoon-style file marks (numbered, persisted per-project) ──────────────
map("n", "<leader>ma", function() require("config.harpoon").add() end, d("Mark current file"))
map("n", "<leader>md", function() require("config.harpoon").remove() end, d("Unmark current file"))
map("n", "<leader>ml", function() require("config.harpoon").list() end, d("List/search marks"))
for i = 1, 9 do
  map("n", "<leader>" .. i, function() require("config.harpoon").jump(i) end, d("Jump to mark " .. i))
end
