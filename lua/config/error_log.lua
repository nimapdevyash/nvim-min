-- Centralized error/warning log for everything that goes through vim.notify
-- (plugin errors, LSP client notices, AI provider failures, ...) — separate
-- from ~/.cache/nvim-min/{install,setup-cli}.log, which only cover the shell
-- installer and the setup CLI. See docs/decisions/index.md#centralized-error-log.
local M = {}

local log_dir = vim.fn.stdpath("state") .. "/nvim-min"
M.log_path = log_dir .. "/errors.log"

local function write(level, title, text)
  vim.fn.mkdir(log_dir, "p")
  local f = io.open(M.log_path, "a")
  if not f then return end
  local prefix = title and (" [" .. title .. "]") or ""
  f:write(("[%s] %s%s: %s\n"):format(vim.fn.strftime("%Y-%m-%dT%H:%M:%S"), level, prefix, text))
  f:close()
end

-- Plain vim.notify wrapper — active until noice.nvim loads and replaces
-- vim.notify wholesale, covering whatever might fire before then.
function M.wrap_notify()
  local original = vim.notify
  vim.notify = function(msg, level, opts)
    local text = type(msg) == "string" and msg or vim.inspect(msg)
    if level == vim.log.levels.ERROR then
      write("ERROR", opts and opts.title, text)
    elseif level == vim.log.levels.WARN then
      write("WARN", opts and opts.title, text)
    end
    return original(msg, level, opts)
  end
end

-- noice.nvim runs a recurring watchdog (see noice/health.lua's 1s interval)
-- that treats any *other* plugin re-wrapping vim.notify after it loads as a
-- misconfiguration — it fires a real, repeating error notification about it,
-- so wrap_notify()'s approach can't just be re-applied once noice is active.
-- Its internal message manager isn't part of that self-check, so hooking
-- Manager.add there instead is the point that doesn't fight noice for
-- ownership of vim.notify.
function M.wrap_noice()
  local ok, Manager = pcall(require, "noice.message.manager")
  if not ok then return end
  local original_add = Manager.add
  Manager.add = function(message)
    if message.event == "notify" and (message.level == "error" or message.level == "warn") then
      local content_ok, text = pcall(function() return message:content() end)
      write(message.level:upper(), message.opts and message.opts.title, content_ok and text or "<unavailable>")
    end
    return original_add(message)
  end
end

return M
