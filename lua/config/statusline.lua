-- Native statusline: no plugin, no icon font dependency. Wired via
-- `vim.o.statusline` in options.lua. Re-evaluated on every statusline redraw,
-- so keep this cheap — no LSP requests, just reads of already-cached state.
local M = {}

local MODES = {
  n = "NORMAL", no = "NORMAL", i = "INSERT", ic = "INSERT",
  v = "VISUAL", V = "V-LINE", ["\22"] = "V-BLOCK",
  c = "COMMAND", R = "REPLACE", Rv = "REPLACE", t = "TERMINAL",
}

function M.mode()
  return MODES[vim.api.nvim_get_mode().mode] or vim.api.nvim_get_mode().mode:upper()
end

-- Reuses gitsigns' own buffer-local state rather than shelling out to git again.
function M.git()
  local head = vim.b.gitsigns_head
  return (head and head ~= "") and (" " .. head) or ""
end

function M.diagnostics()
  local count = vim.diagnostic.count(0)
  local err = count[vim.diagnostic.severity.ERROR]
  local warn = count[vim.diagnostic.severity.WARN]
  local parts = {}
  if err and err > 0 then parts[#parts + 1] = "E:" .. err end
  if warn and warn > 0 then parts[#parts + 1] = "W:" .. warn end
  return #parts > 0 and (" " .. table.concat(parts, " ")) or ""
end

function M.lsp()
  local names = {}
  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    names[#names + 1] = client.name
  end
  return #names > 0 and (" " .. table.concat(names, ",")) or ""
end

function M.render()
  return table.concat({
    " ", M.mode(), " %f%m%r", M.git(),
    "%=",
    M.diagnostics(), M.lsp(), " %y  %l:%c  %P ",
  })
end

return M
