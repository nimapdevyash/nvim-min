-- Native statusline: no plugin, no icon font dependency beyond the Powerline
-- "round" glyphs below (your terminal already renders these — proven by the
-- tmux bar this is modeled on). Wired via `vim.o.statusline` in options.lua.
-- Re-evaluated on every redraw, so keep this cheap — no LSP requests, just
-- reads of already-cached state.
--
-- Two zones, mirroring the tmux bar: branch pill + filepath on the left,
-- language/position/mode pills on the right — and the bar itself has no
-- background of its own (bg = NONE), so pills float directly on the
-- terminal's background instead of sitting on a solid strip, matching the
-- tmux bar's glass look. No LSP client list — that's what <leader>ci
-- (:checkhealth vim.lsp) is for.
local M = {}

-- ple-left_half_circle_thick / ple-right_half_circle_thick — verified
-- against the Nerd Fonts glyph names: U+E0B6 is the "(" shaped left cap,
-- U+E0B4 the ")" shaped right cap.
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

-- name -> onedark.colors palette key, built + iterated together in
-- setup_highlights() so each pill's "Cap" variant never drifts out of sync.
local PILL_GROUPS = {
  StatuslineModeNormal = "blue",
  StatuslineModeInsert = "green",
  StatuslineModeVisual = "purple",
  StatuslineModeReplace = "red",
  StatuslineModeCommand = "orange",
  StatuslineModeTerminal = "cyan",
  StatuslineGitPill = "green",
  StatuslineLangPill = "yellow",
  StatuslinePosPill = "purple",
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
  return (head and head ~= "") and pill(head, "StatuslineGitPill") or ""
end

function M.diagnostics()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR]
  local warn = count[vim.diagnostic.severity.WARN]
  local parts = {}
  if err and err > 0 then parts[#parts + 1] = "%#StatuslineDiagError#E:" .. err .. "%*" end
  if warn and warn > 0 then parts[#parts + 1] = "%#StatuslineDiagWarn#W:" .. warn .. "%*" end
  return #parts > 0 and (table.concat(parts, " ") .. " ") or ""
end

function M.render()
  -- laststatus=3 means one global statusline for the whole tabpage — there's
  -- no such thing as a window-local override to "hide it on the dashboard",
  -- so render() itself has to check what's actually on screen.
  if vim.bo.filetype == "dashboard" then return "" end

  local mode_label, mode_hl = M.mode()
  local filetype = vim.bo.filetype ~= "" and vim.bo.filetype or "no ft"

  return table.concat({
    -- left zone: branch, then the file right after it
    " ", M.git(),
    " %#StatuslineFile#%f%m%r%*",
    "%=",
    -- right zone: mode, language, then everything else
    " ", pill(mode_label, mode_hl), " ",
    pill(filetype, "StatuslineLangPill"), " ",
    M.diagnostics(),
    pill("%l:%c  %P", "StatuslinePosPill"), " ",
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

  -- The bar itself has no background — onedark's `transparent` option only
  -- clears Normal/SignColumn/etc, not StatusLine (most colorschemes treat
  -- the statusline as chrome, not editor background, on purpose). Clearing
  -- it here is what makes the pills float directly on the terminal's own
  -- background instead of sitting on a solid strip, matching the tmux bar.
  hl("StatusLine", { bg = "NONE" })
  hl("StatusLineNC", { bg = "NONE" })
end

return M
