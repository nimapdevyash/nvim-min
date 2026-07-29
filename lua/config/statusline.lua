-- Native statusline: no plugin, no icon font dependency. Wired via
-- `vim.o.statusline` in options.lua. Re-evaluated on every statusline redraw,
-- so keep this cheap — no LSP requests, just reads of already-cached state.
--
-- Deliberately minimal: mode, filename, git branch, diagnostics (only when
-- present), filetype, cursor position. No LSP client list — that's what
-- <leader>ci (:checkhealth vim.lsp) is for, not something to show on every
-- keystroke.
local M = {}

local MODES = {
  n = { "NORMAL", "StatuslineModeNormal" },
  no = { "NORMAL", "StatuslineModeNormal" },
  i = { "INSERT", "StatuslineModeInsert" },
  ic = { "INSERT", "StatuslineModeInsert" },
  v = { "VISUAL", "StatuslineModeVisual" },
  V = { "V-LINE", "StatuslineModeVisual" },
  ["\22"] = { "V-BLOCK", "StatuslineModeVisual" },
  c = { "COMMAND", "StatuslineModeCommand" },
  R = { "REPLACE", "StatuslineModeReplace" },
  Rv = { "REPLACE", "StatuslineModeReplace" },
  t = { "TERMINAL", "StatuslineModeTerminal" },
}

function M.mode()
  local raw = vim.api.nvim_get_mode().mode
  local entry = MODES[raw]
  if entry then return entry[1], entry[2] end
  return raw:upper(), "StatuslineModeNormal"
end

-- Reuses gitsigns' own buffer-local state rather than shelling out to git again.
function M.git()
  local head = vim.b.gitsigns_head
  return (head and head ~= "") and ("%#StatuslineGit# " .. head .. " %*") or ""
end

function M.diagnostics()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR]
  local warn = count[vim.diagnostic.severity.WARN]
  local parts = {}
  if err and err > 0 then parts[#parts + 1] = "%#StatuslineDiagError#E:" .. err .. "%*" end
  if warn and warn > 0 then parts[#parts + 1] = "%#StatuslineDiagWarn#W:" .. warn .. "%*" end
  return #parts > 0 and (" " .. table.concat(parts, " ") .. " ") or ""
end

function M.render()
  -- laststatus=3 means one global statusline for the whole tabpage — there's
  -- no such thing as a window-local override to "hide it on the dashboard",
  -- so render() itself has to check what's actually on screen.
  if vim.bo.filetype == "dashboard" then return "" end

  local label, hl = M.mode()
  return table.concat({
    "%#" .. hl .. "# " .. label .. " %*",
    " %f%m%r",
    M.git(),
    "%=",
    M.diagnostics(),
    "%#StatuslineMuted# %y  %l:%c  %P %*",
  })
end

function M.setup_highlights()
  local ok, colors = pcall(require, "onedark.colors")
  if not ok then return end

  local function hl(name, opts) vim.api.nvim_set_hl(0, name, opts) end

  hl("StatuslineModeNormal", { bg = colors.blue, fg = colors.bg0, bold = true })
  hl("StatuslineModeInsert", { bg = colors.green, fg = colors.bg0, bold = true })
  hl("StatuslineModeVisual", { bg = colors.purple, fg = colors.bg0, bold = true })
  hl("StatuslineModeReplace", { bg = colors.red, fg = colors.bg0, bold = true })
  hl("StatuslineModeCommand", { bg = colors.orange, fg = colors.bg0, bold = true })
  hl("StatuslineModeTerminal", { bg = colors.cyan, fg = colors.bg0, bold = true })
  hl("StatuslineGit", { fg = colors.orange })
  hl("StatuslineDiagError", { fg = colors.red })
  hl("StatuslineDiagWarn", { fg = colors.yellow })
  hl("StatuslineMuted", { fg = colors.grey })
end

return M
