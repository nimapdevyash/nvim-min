-- AI features, provider-agnostic — gemini/openai/anthropic all work, chosen
-- via `nvim-min-setup ai` (writes `ai_provider` to settings.json + the
-- matching *_API_KEY to secrets.env, loaded by init.lua before plugins run).
-- See README.md and docs/decisions/index.md#multi-provider-ai.
--
-- Both plugins here are individually toggleable from the CLI
-- (`nvim-min-setup features`) — disabled ones don't even load (lazy.nvim
-- `enabled = false`), so turning AI off is a real startup-cost saving, not
-- just a hidden no-op.
local settings = require("config.user_settings").load()
local features = settings.features
-- Independent per feature — chat and ghost text can each use a different
-- provider (e.g. Claude for chat, Gemini for ghost text), since they're
-- already two separate plugins for two different jobs. See
-- docs/decisions/index.md#multi-provider-ai.
local chat_provider = settings.ai_provider.chat
local ghost_provider = settings.ai_provider.ghost_text

-- codecompanion.nvim's adapter names line up with the provider names this
-- config uses directly (gemini/openai/anthropic) — no mapping needed there.
-- minuet-ai.nvim is the one exception: its provider is called "claude", not
-- "anthropic", for the same backend (verified against both plugins' source,
-- not assumed — they otherwise agree on env var names: GEMINI_API_KEY/
-- OPENAI_API_KEY/ANTHROPIC_API_KEY either way).
local MINUET_PROVIDER = { gemini = "gemini", openai = "openai", anthropic = "claude" }

return {
  {
    "olimorris/codecompanion.nvim",
    enabled = features.ai_chat,
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    opts = {
      adapters = {
        http = {
          -- Only gemini gets a model override here — chat quality on
          -- openai/anthropic's own defaults (gpt-5.x / claude-sonnet) is
          -- already the right tradeoff for an on-demand tool; this override
          -- exists specifically because codecompanion's gemini adapter
          -- otherwise defaults to a lighter model than wanted for chat.
          extend = chat_provider == "gemini" and {
            gemini = {
              schema = {
                model = { default = "gemini-2.5-pro" },
              },
            },
          } or nil,
        },
      },
      strategies = {
        chat = { adapter = chat_provider },
        inline = { adapter = chat_provider },
      },
      display = {
        chat = { show_settings = false },
      },
    },
  },

  {
    "milanglacier/minuet-ai.nvim",
    enabled = features.ghost_text,
    event = "InsertEnter",
    opts = {
      provider = MINUET_PROVIDER[ghost_provider] or "gemini",
      provider_options = ghost_provider == "gemini" and {
        gemini = {
          -- 2.0-flash over 2.5: lower latency/cost, thinking mode adds
          -- nothing for line-completion and only slows down ghost text.
          -- openai/claude get minuet's own defaults (gpt-5.4-nano,
          -- claude-haiku-4-5) — already fast/cheap models chosen by minuet
          -- specifically for this job, no override needed.
          model = "gemini-2.0-flash",
          optional = {
            generationConfig = {
              maxOutputTokens = 256,
              thinkingConfig = { thinkingBudget = 0 },
            },
          },
        },
      } or nil,
      virtualtext = {
        auto_trigger_ft = {
          "javascript", "typescript", "javascriptreact", "typescriptreact",
          "python", "lua", "sh", "bash", "yaml", "dockerfile", "terraform",
          "json", "html", "css",
        },
        keymap = {
          -- whole-suggestion accept is `<Tab>`, wired in keymaps.lua so it
          -- chains through blink.cmp's own <Tab> instead of fighting it
          accept_line = "<A-a>",
          accept_n_lines = "<A-z>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<A-e>",
        },
      },
    },
  },
}
