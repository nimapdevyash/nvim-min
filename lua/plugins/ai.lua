-- Gemini-powered AI. Set your key with `nvim-min-setup ai` (writes
-- ~/.config/nvim-min/user/secrets.env, loaded by init.lua before plugins run)
-- rather than exporting GEMINI_API_KEY by hand. See README.md.
--
-- Both plugins here are individually toggleable from the CLI
-- (`nvim-min-setup features`) — disabled ones don't even load (lazy.nvim
-- `enabled = false`), so turning AI off is a real startup-cost saving, not
-- just a hidden no-op.
local features = require("config.user_settings").load().features

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
          extend = {
            gemini = {
              schema = {
                model = { default = "gemini-2.5-pro" },
              },
            },
          },
        },
      },
      strategies = {
        chat = { adapter = "gemini" },
        inline = { adapter = "gemini" },
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
      provider = "gemini",
      provider_options = {
        gemini = {
          -- 2.0-flash over 2.5: lower latency/cost, thinking mode adds
          -- nothing for line-completion and only slows down ghost text
          model = "gemini-2.0-flash",
          optional = {
            generationConfig = {
              maxOutputTokens = 256,
              thinkingConfig = { thinkingBudget = 0 },
            },
          },
        },
      },
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
