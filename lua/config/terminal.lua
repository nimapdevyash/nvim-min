-- Floating terminal, native Neovim only (nvim_open_win + jobstart term=true).
-- Replaces toggleterm.nvim: same "toggle keeps the process alive" behavior,
-- no plugin needed for something this small.
local M = {}

local terminals = {} ---@type table<string, {buf: integer, win: integer?}>

local function float_win(buf)
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)
  return vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
  })
end

---@param key string unique id so repeat toggles reuse the same process
---@param cmd string|string[]|nil defaults to the user's shell
---@param opts? { close_on_exit?: boolean } close_on_exit (default true) auto-closes
---   the float when the job exits — fine for an interactive shell/lazygit, but
---   wrong for a one-shot command (e.g. `kitten icat`) that exits the instant
---   it's done rendering: that would close the window before you see anything.
function M.toggle(key, cmd, opts)
  opts = opts or {}
  local term = terminals[key]

  if term and vim.api.nvim_buf_is_valid(term.buf) then
    if term.win and vim.api.nvim_win_is_valid(term.win) then
      vim.api.nvim_win_close(term.win, false)
      term.win = nil
    else
      term.win = float_win(term.buf)
      vim.cmd.startinsert()
    end
    return
  end

  local buf = vim.api.nvim_create_buf(false, true)
  local win = float_win(buf)
  vim.fn.jobstart(cmd or vim.o.shell, {
    term = true,
    on_exit = function()
      if opts.close_on_exit == false then return end
      terminals[key] = nil
      if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end
    end,
  })
  terminals[key] = { buf = buf, win = win }
end

function M.toggle_terminal() M.toggle("shell") end
function M.toggle_lazygit() M.toggle("lazygit", "lazygit") end

return M
