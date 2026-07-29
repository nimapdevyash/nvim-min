# LSP & performance

## Servers configured

| Stack | Servers |
|---|---|
| TypeScript/JS | `vtsls` (see [why not `ts_ls`](/decisions/#vtsls)) + `eslint` (auto-fixes on save) |
| Web | `html`, `cssls`, `tailwindcss` |
| Data | `jsonls`, `yamlls` — both with [SchemaStore](https://www.schemastore.org/) validation |
| Lua | `lua_ls` |
| Python (Gen AI work) | `basedpyright` + `ruff` |
| DevOps | `bashls`, `dockerls`, `docker_compose_language_service`, `terraformls` |
| Docs | `marksman` |

Formatters (conform.nvim): `prettierd` (JS/TS/JSON/YAML/HTML/CSS/MD), `stylua` (Lua), `shfmt`
(shell), `ruff_format` (Python), `terraform_fmt` (needs the `terraform` CLI installed separately —
Mason doesn't manage it).

Adding a server is two steps — see `lua/plugins/lsp.lua`: add its `nvim-lspconfig` name to
`ensure_installed`, and only add a `vim.lsp.config("name", {...})` override if the defaults
genuinely aren't enough.

## Performance discipline (Zed-inspired)

Zed's speed comes from doing LSP/indexing work off the UI thread and being disciplined about what
triggers it in the first place. The Neovim-native equivalents applied here:

- **No duplicate highlighting work.** LSP semantic tokens are explicitly disabled on attach
  (`client.server_capabilities.semanticTokensProvider = nil`, in the `LspAttach` callback in
  `lua/plugins/lsp.lua`) — treesitter already highlights syntax, so semantic tokens would just
  redo that per edit for servers like vtsls/eslint, for little extra benefit. See
  [Decision history](/decisions/#semantic-tokens).
- **Inlay hints are opt-in, not on by default.** They cost an LSP request per visible range on
  every scroll/edit on large files. Toggle with `<leader>ch`.
- **Diagnostics don't recompute on every keystroke** (`update_in_insert = false`).
- **Text-change notifications are debounced 150ms** — confirmed as Neovim's own default by
  reading `vim/lsp/_changetracking.lua` in `$VIMRUNTIME`, not assumed from memory.
- **File-watching exclusions** are also already handled by Neovim core
  (`vim/lsp/_watchfiles.lua` excludes `node_modules/*/**`, `.git/objects`, `.hg/store` from
  polling by default) — checked, and deliberately *not* re-implemented or disabled wholesale,
  since doing so would cost real features (e.g. eslint reacting to config file changes) for a
  gain Neovim already provides for free.
- **`vtsls` inlay hint kinds are pared down** in its settings (only parameter names on literals) —
  the rest cost more to compute than they're worth day-to-day.
- Mason-installed binaries are cached on disk after first install — nothing to "warm up" on every
  launch.

The recurring theme: before adding a "speed" tweak, check whether Neovim core already does it.
Two of the items above (debounce, file-watch exclusion) turned out to already be handled — adding
config for them would have been redundant at best, and a maintenance trap if core's defaults ever
change and this config's copy drifts out of sync.
