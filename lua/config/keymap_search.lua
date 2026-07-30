-- Plain-text key -> description export of every global keymap, regenerated
-- from the live registry each time the picker opens (see keymap_search.picker
-- below) — a real .txt file to browse/grep outside nvim too, but nothing
-- about it is hand-maintained, so it can't drift from keymaps.lua the way a
-- second hand-typed copy would (CLAUDE.md principle #3: keymaps.lua is the
-- single source of truth).
local M = {}

local MODES = { "n", "v", "x", "s", "o", "i", "c", "t" }

--- @return {mode: string, lhs: string, raw_lhs: string, desc: string}[]
local function collect()
  local seen = {}
  local entries = {}
  for _, mode in ipairs(MODES) do
    for _, list in ipairs({ vim.api.nvim_get_keymap(mode), vim.api.nvim_buf_get_keymap(0, mode) }) do
      for _, k in ipairs(list) do
        -- Skip Neovim's own built-in defaults (e.g. visual-mode `#`/`&`/`*`)
        -- — they carry an auto-generated `:help <tag>` "description," not a
        -- real one, and this list is specifically about what *this config*
        -- maps, not core Vim motions.
        if k.desc and k.desc ~= "" and not k.desc:match("^:help ") then
          -- Content-based, not mode-based: a single `map("v", ...)` call
          -- reports back under "v"/"x"/"s" separately when queried per-mode
          -- (Neovim's visual/select mode grouping), which would otherwise
          -- show the exact same binding three times. Same lhs + same desc
          -- is the same real binding as far as this list is concerned —
          -- mode was already dropped from display for the same reason
          -- (see docs/decisions/index.md#keymaps-picker-format).
          local seen_key = k.lhs .. "\0" .. k.desc
          if not seen[seen_key] then
            seen[seen_key] = true
            table.insert(entries, {
              mode = mode,
              lhs = require("snacks").util.normkey(k.lhs),
              raw_lhs = k.lhs,
              desc = k.desc,
            })
          end
        end
      end
    end
  end
  table.sort(entries, function(a, b) return a.lhs < b.lhs end)
  return entries
end

local function txt_path()
  local dir = vim.fn.stdpath("state") .. "/nvim-min"
  vim.fn.mkdir(dir, "p")
  return dir .. "/keymaps.txt"
end

--- Regenerate keymaps.txt (key<TAB>description, one per line) from the live
--- keymap registry. Returns the same data as a list, so the picker below
--- doesn't need to re-read the file it just wrote.
function M.export()
  local entries = collect()
  local lines = {}
  for _, e in ipairs(entries) do
    table.insert(lines, e.lhs .. "\t" .. e.desc)
  end
  local f = io.open(txt_path(), "w")
  if f then
    f:write(table.concat(lines, "\n") .. "\n")
    f:close()
  end
  return entries
end

--- Fuzzy-searchable key/description list, no preview pane (the description
--- is already fully visible in the row itself, so a preview would just
--- repeat it). <cr> also executes the mapping directly, same as the
--- registry-backed picker this replaced.
function M.picker()
  local entries = M.export()
  local items = {}
  for i, e in ipairs(entries) do
    items[i] = { text = e.lhs .. "  " .. e.desc, lhs = e.lhs, desc = e.desc, raw_lhs = e.raw_lhs }
  end

  return require("snacks").picker.pick({
    title = "Keymaps",
    items = items,
    layout = { preview = false },
    format = function(item)
      return {
        { require("snacks").picker.util.align(item.lhs, 16), "SnacksPickerKeymapLhs" },
        { "  " },
        { item.desc },
      }
    end,
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.api.nvim_input(vim.api.nvim_replace_termcodes(item.raw_lhs, true, true, true))
      end
    end,
  })
end

return M
