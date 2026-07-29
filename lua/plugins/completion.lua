return {
  "saghen/blink.cmp",
  version = "1.*", -- pin to stable v1 (v2 is a moving target); ships prebuilt binaries, no build step
  event = "InsertEnter",
  opts = {
    keymap = { preset = "super-tab" }, -- <Tab>/<S-Tab> select + snippet jump, <CR> accept, <C-e> close
    appearance = { nerd_font_variant = "mono" },
    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 200 },
      menu = { border = "rounded" },
      ghost_text = { enabled = true },
    },
    signature = { enabled = true, window = { border = "rounded" } },
    sources = {
      default = { "lsp", "path", "snippets", "buffer" },
    },
    fuzzy = { implementation = "prefer_rust_with_warning" },
  },
  opts_extend = { "sources.default" },
}
