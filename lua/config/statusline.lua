-- Native statusline: no plugin, no icon font dependency beyond the two
-- Powerline "round" glyphs below (your terminal already renders these
-- correctly — proven by the tmux bar this was modeled on). Wired via
-- `vim.o.statusline` in options.lua. Re-evaluated on every statusline redraw,
-- so keep this cheap — no LSP requests, just reads of already-cached state.
--
-- Deliberately minimal: mode + git branch as colored pills (like the tmux
-- bar's branch/window pills), filename, diagnostics (only when present),
-- filetype, cursor position. No LSP client list — that's what <leader>ci
-- (:checkhealth vim.lsp) is for, not something to show on every keystroke.
local M = {}

-- ple-left_half_circle_thick / ple-right_half_circle_thick — verified
-- against the Nerd Fonts glyph names, not guessed: U+E0B6 is the "(" shaped
-- left cap, U+E0B4 the ")" shaped right cap.
local PILL_LEFT = "\u{E0B6}"
local PILL_RIGHT = "\u{E0B4}"

--- @param text string
--- @param hl_group string base highlight group name; hl_group.."Cap" must
---   also exist (fg = this group's bg, bg = NONE) — see setup_highlights()
local function pill(text, hl_group)
  return table.concat({
    "%#", hl_group, "Cap#", PILL_LEFT,
    "%#", hl_group, "# ", text, " ",
    "%#", hl_group, "Cap#", PILL_RIGHT,
    "%*",
  })
end

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

-- name -> onedark.colors palette key, used both to build the "Cap" variant
-- and to iterate in setup_highlights() without repeating each group twice.
local PILL_GROUPS = {
  StatuslineModeNormal = "blue",
  StatuslineModeInsert = "green",
  StatuslineModeVisual = "purple",
  StatuslineModeReplace = "red",
  StatuslineModeCommand = "orange",
  StatuslineModeTerminal = "cyan",
  StatuslineGitPill = "green",
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
  return (head and head ~= "") and (" " .. pill(head, "StatuslineGitPill")) or ""
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
    " ", pill(label, hl),
    " %#StatuslineFile#%f%m%r%*",
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

  for group, color_key in pairs(PILL_GROUPS) do
    local color = colors[color_key]
    hl(group, { bg = color, fg = colors.bg0, bold = true })
    -- the cap's "outer" side is NONE to match the theme's transparent
    -- background — the terminal's own bg shows through, same as everywhere else
    hl(group .. "Cap", { fg = color, bg = "NONE" })
  end

  hl("StatuslineFile", { fg = colors.fg })
  hl("StatuslineDiagError", { fg = colors.red })
  hl("StatuslineDiagWarn", { fg = colors.yellow })
  hl("StatuslineMuted", { fg = colors.grey })
end

return M
