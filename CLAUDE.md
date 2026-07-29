# CLAUDE.md

Guide for AI coding agents (Claude Code or otherwise) working in this repo. Read this before
making changes.

## What this is

A from-scratch, minimalist Neovim config optimized for **MERN + DevOps + Gen AI** development,
built for speed over feature-completeness. It is one of potentially several Neovim configs on
this machine, switched between via `NVIM_APPNAME` (see README.md → "Switching configs"). This
config lives at `~/.config/nvim-min` and must never assume it's the only or default config —
another config (LazyVim, at `~/.config/nvim`) exists as a sibling and must not be touched or
referenced by anything in here.

## Non-negotiable principles

1. **Minimalism is the point.** Before adding a plugin, ask: does Neovim already do this
   natively (folding, commenting via `gc`, LSP hover/rename/references), or does an existing
   plugin already cover it? Don't add a plugin for marginal convenience. Don't add "nice to have"
   config for features nobody asked for.
2. **`lua/config/keymaps.lua` is the single source of truth for keybindings.** No which-key or
   similar popup plugin — ever. New keybindings go in that one file, grouped under the existing
   section headers, with a `desc` on every mapping (this is what makes `<leader>?` / fzf-lua's
   keymap picker useful — it reads `desc`). Update `KEYBINDINGS.md` to match whenever
   `keymaps.lua` changes; it's documentation, not the source of truth, and drifting is a bug.
3. **Prefer native Neovim APIs over plugin frameworks.** LSP servers are enabled with
   `vim.lsp.config()` / `vim.lsp.enable()` (Neovim 0.11+), never `require('lspconfig').setup{}`
   (deprecated upstream, shows warnings). Check `:h lsp-config` when in doubt.
4. **This ecosystem moves fast — verify, don't assume from training data.** Plugins referenced
   here (blink.cmp, nvim-treesitter, mason-lspconfig, codecompanion.nvim) have had recent breaking
   rewrites and org transfers (e.g. `mini.nvim` moved from `echasnovski` → `nvim-mini`,
   `mason.nvim`/`mason-lspconfig.nvim` moved from `williamboman` → `mason-org`, blink.cmp has an
   actively-breaking v2 alongside a stable v1). Before adding or upgrading a plugin, check its
   current README/source on GitHub (`gh api repos/<owner>/<repo>/contents/README.md -q .content
   | base64 -d`) rather than trusting memorized APIs. This config intentionally pins
   `blink.cmp` to `version = "1.*"` and `nvim-treesitter` to `branch = "master"` for exactly this
   reason — confirm those pins are still the right call before changing them.
5. **Never hardcode secrets.** The Gemini adapter reads `GEMINI_API_KEY` from the environment
   (`lua/plugins/ai.lua`). Don't put API keys in any file in this repo.
6. **Keep LSP servers fast.** `update_in_insert = false` and per-server settings in
   `lua/plugins/lsp.lua` exist for a reason (e.g. `vtsls` inlay hints are deliberately pared down,
   diagnostics don't recompute on every keystroke). If you add a server, don't let it regress
   this — test on a real TypeScript file, not just that it attaches.

## Structure

```
init.lua                    leader keys, then requires config.options → config.lazy →
                             config.keymaps → config.autocmds, in that order (order matters:
                             lazy needs mapleader set first; keymaps need plugins registered
                             so lazy-loading `keys = {...}` specs work)
lua/config/
  options.lua                 vim.opt, disabled built-ins/providers, diagnostics/fold config
  keymaps.lua                 ALL keybindings (see principle #2)
  autocmds.lua                 general-purpose autocmds only — LSP-attach keymaps/autocmds live
                               in lua/plugins/lsp.lua's config() function, next to the LSP setup
                               they depend on
  lazy.lua                    lazy.nvim bootstrap
lua/plugins/*.lua              one file per concern, each returning a lazy.nvim plugin spec
                               (or list of specs)
```

## How to test a change

There's no test suite — this is an editor config. Verify with headless Neovim before calling
something done:

```sh
NVIM_APPNAME=nvim-min nvim --headless -c "quit"          # catches syntax/load errors
NVIM_APPNAME=nvim-min nvim path/to/real-file.ts           # open a real file, check :LspInfo,
                                                           # :checkhealth vim.lsp, that gd/K/<leader>ca
                                                           # actually work
```

When changing `lua/plugins/lsp.lua`, test against real `.ts`/`.py`/`.tf` files, not empty
buffers — inlay hints, eslint autofix-on-save, and schema validation only show up with real
content.

## Common tasks

- **Add an LSP server**: add its `nvim-lspconfig` name to `ensure_installed` in
  `lua/plugins/lsp.lua`. Only add a `vim.lsp.config("name", {...})` override if defaults are
  insufficient — check `nvim-lspconfig`'s `lsp/<name>.lua` on GitHub for what's configurable.
- **Add a formatter**: add to `formatters_by_ft` in `lua/plugins/formatting.lua`, and to
  `mason-tool-installer`'s `ensure_installed` in `lua/plugins/lsp.lua` if it's not already
  installed as an LSP server package.
- **Add a keybinding**: `lua/config/keymaps.lua` only, with a `desc`. Mirror it in
  `KEYBINDINGS.md`.
- **Add a plugin**: justify it against principle #1 first. If it's genuinely needed, add a new
  `lua/plugins/<concern>.lua` file (or extend an existing one if it fits an existing concern) —
  don't dump unrelated plugins into one file.
