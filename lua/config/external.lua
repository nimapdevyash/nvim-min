-- Outsource file-preview to tools that already exist on the system instead of
-- adding an nvim plugin for it (image.nvim and friends pull in real weight:
-- a rendering backend, extra deps, redraw-on-scroll overhead). Neovim just
-- shells out; the actual work happens in a real terminal or the OS's own
-- default app, at zero cost to nvim's own startup or runtime.
local M = {}

--- Best-effort "what file are we talking about": a snacks explorer entry
--- under the cursor, else a path under the cursor (<cfile>), else the
--- current buffer.
local function target_path()
  if vim.bo.filetype == "snacks_picker_list" then
    local ok, picker = pcall(function() return require("snacks").picker.get({ source = "explorer" })[1] end)
    local item = ok and picker and picker:current()
    if item and item.file then return item.file end
  end

  local cfile = vim.fn.expand("<cfile>")
  if cfile ~= "" and vim.fn.filereadable(cfile) == 1 then
    return vim.fn.fnamemodify(cfile, ":p")
  end

  return vim.api.nvim_buf_get_name(0)
end

--- Open in whatever the OS has configured as the default app for this file
--- type — images, SVGs, PDFs, anything. Fire-and-forget, never blocks nvim.
function M.open_externally()
  local path = target_path()
  if path == "" then
    return vim.notify("external: no file to open", vim.log.levels.WARN)
  end

  local opener = (vim.fn.executable("xdg-open") == 1 and "xdg-open")
    or (vim.fn.executable("open") == 1 and "open")
  if not opener then
    return vim.notify("external: no xdg-open/open on PATH", vim.log.levels.WARN)
  end

  vim.fn.jobstart({ opener, path }, { detach = true })
  vim.notify("Opened " .. vim.fn.fnamemodify(path, ":t") .. " externally", vim.log.levels.INFO)
end

--- Render inline in a floating terminal via Kitty's graphics protocol
--- (`kitten icat`), for when you'd rather stay in the terminal than pop a GUI
--- viewer. Falls back to open_externally() when kitten isn't available.
function M.preview_in_terminal()
  local path = target_path()
  if path == "" then
    return vim.notify("external: no file to preview", vim.log.levels.WARN)
  end

  if vim.fn.executable("kitten") == 1 then
    -- close_on_exit=false: icat exits the instant it's done rendering: the
    -- window must stay up so you can actually see the image
    require("config.terminal").toggle("preview", { "kitten", "icat", path }, { close_on_exit = false })
  else
    M.open_externally()
  end
end

return M
