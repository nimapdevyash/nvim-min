-- Machine-local settings and secrets, managed by the separate `nvim-min-setup`
-- CLI (bin/nvim-min-setup) rather than by hand-editing Lua — keeps API keys
-- and personal theme choice out of the tracked config entirely.
-- Files live under stdpath("config") .. "/user/" and are gitignored.
local M = {}

local user_dir = vim.fn.stdpath("config") .. "/user"

local DEFAULTS = {
  theme = "mocha", -- catppuccin flavour: latte | frappe | macchiato | mocha
  transparent = true,
  ai_provider = "gemini",
  features = {
    ghost_text = true, -- minuet-ai.nvim (Gemini inline ghost-text suggestions)
    ai_chat = true, -- codecompanion.nvim (Gemini chat / inline assistant)
  },
}

--- Reads user/settings.json (theme, provider choice, ...). Always returns a
--- full table — falls back to DEFAULTS for anything missing or if the file
--- doesn't exist yet (first run, before `nvim-min-setup` has been used).
function M.load()
  local path = user_dir .. "/settings.json"
  local f = io.open(path, "r")
  if not f then return vim.deepcopy(DEFAULTS) end

  local content = f:read("*a")
  f:close()

  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then return vim.deepcopy(DEFAULTS) end

  return vim.tbl_deep_extend("force", vim.deepcopy(DEFAULTS), decoded)
end

--- Reads user/secrets.env (KEY=value per line, shell-style) and exports any
--- key not already set in the environment. Safe to call even if the file
--- doesn't exist (nothing happens — plugins just see no API key and no-op).
function M.load_secrets()
  local f = io.open(user_dir .. "/secrets.env", "r")
  if not f then return end

  for line in f:lines() do
    local key, value = line:match("^%s*([%w_]+)%s*=%s*(.-)%s*$")
    if key and value ~= "" and vim.env[key] == nil then
      vim.env[key] = value
    end
  end
  f:close()
end

return M
