-- Gemini-powered AI assistant. Requires: export GEMINI_API_KEY=... in your shell
-- (get a key at https://aistudio.google.com/apikey). See README.md.
return {
  "olimorris/codecompanion.nvim",
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
}
