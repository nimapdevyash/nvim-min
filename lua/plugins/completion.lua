return {
  "saghen/blink.cmp",
  version = "1.*", -- pin to stable v1 (v2 is a moving target); ships prebuilt binaries, no build step
  event = "InsertEnter",
  opts = {
    keymap = {
      preset = "super-tab", -- <S-Tab>/<Up>/<Down>/<C-n>/<C-p>/<C-b>/<C-f>/<C-k>/<C-e>/<C-space>
      -- <Tab> and <CR> accept are handled entirely by lua/config/keymaps.lua
      -- instead of here — see docs/decisions/index.md#blink-expr-mapping-bug.
      -- blink's own keymap system always registers insert-mode mappings as
      -- Neovim `expr` mappings (see saghen/blink.cmp's keymap/apply.lua),
      -- which run under `textlock`; in this environment,
      -- `require('blink.cmp').is_visible()` reliably reads back stale/false
      -- specifically when called from inside that restricted evaluation
      -- context, even though the exact same call from a plain callback reads
      -- correctly — so accept silently never fires and Tab/Enter just insert
      -- themselves. Setting both to `false` here stops blink from installing
      -- its own (non-functional) mapping for them at all, so there's only
      -- ever one mapping in play for each key.
      ["<Tab>"] = false,
      ["<CR>"] = false,
    },
    appearance = { nerd_font_variant = "mono" },
    completion = {
      -- window.border defaults to nil (no border at all) — easy to miss
      -- since menu/signature both default to a border already and this one
      -- doesn't, and with onedark's transparent floats (see
      -- lua/plugins/colorscheme.lua) a borderless doc popup has nothing at
      -- all to visually separate it from whatever's behind the terminal.
      documentation = { auto_show = true, auto_show_delay_ms = 200, window = { border = "rounded" } },
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
