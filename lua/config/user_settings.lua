-- Machine-local settings and secrets, managed by the separate `nvim-min-setup`
-- CLI (bin/nvim-min-setup) rather than by hand-editing Lua — keeps API keys
-- and personal theme choice out of the tracked config entirely.
-- Files live under stdpath("config") .. "/user/" and are gitignored.
local M = {}

local user_dir = vim.fn.stdpath("config") .. "/user"

local DEFAULTS = {
  theme = "dark", -- onedark style: dark | darker | cool | deep | warm | warmer | light
  transparent = true,
  -- Independent per-feature, not one global choice: chat (codecompanion) and
  -- ghost text (minuet-ai) are already two separate plugins for two
  -- different jobs (quality vs. speed, see #two-ai-plugins) — nothing stops
  -- you running, say, Claude for chat and Gemini for ghost text. Each value
  -- is gemini | openai | anthropic — see lua/plugins/ai.lua.
  ai_provider = { chat = "gemini", ghost_text = "gemini" },
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

  -- Migrate a pre-multi-provider settings.json (ai_provider as a single
  -- string) into the current per-feature shape, rather than letting
  -- tbl_deep_extend clobber the DEFAULTS table with a bare string where it
  -- expects a table.
  if type(decoded.ai_provider) == "string" then
    decoded.ai_provider = { chat = decoded.ai_provider, ghost_text = decoded.ai_provider }
  end

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
