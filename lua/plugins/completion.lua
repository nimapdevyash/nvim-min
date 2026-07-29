return {
  "saghen/blink.cmp",
  version = "1.*", -- pin to stable v1 (v2 is a moving target); ships prebuilt binaries, no build step
  event = "InsertEnter",
  opts = {
    keymap = { preset = "super-tab" }, -- <Tab>/<S-Tab> select + snippet jump, <CR> accept, <C-e> close
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = {
        border = "rounded",
        auto_show = true, -- default, made explicit: never a manual-trigger-only setup
      },
      -- show suggestions immediately on entering insert mode, not just after
      -- the first keystroke — matters for "I want them there when I type"
      trigger = { show_on_insert = true },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = {
      implementation = "prefer_rust_with_warning", -- native matcher, 0.5-4ms/keystroke
      -- frecency (learns your most-used completions) and proximity (boosts
      -- matches near other uses of the same word in-buffer) are both
      -- defaults already — the real precision levers, not a config to add.
    },
  },
  opts_extend = { "sources.default" },
}
