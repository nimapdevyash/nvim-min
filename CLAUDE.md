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

Configuration is deliberately split in two: nvim-min itself (this Lua config — stays minimal,
never prompts for input at runtime) and `nvim-min-setup` (`bin/nvim-min-setup` — a separate Node
CLI, built with `@clack/prompts`, that owns all interactive setup: API keys, theme, feature
toggles). Don't blur this line by adding interactive prompts, settings UIs, or setup wizards to
the Lua side — that belongs in the CLI, which is allowed to have dependencies and complexity the
editor itself isn't. `install.sh` at the repo root is the third piece: a bootstrap script that
installs system requirements, wires up `nvim-min-setup`/`nvims`, and bootstraps nvim itself on a
fresh clone. All three are independent — nvim never imports, shells out to, or waits on either of
the other two at runtime.

## Non-negotiable principles

1. **Minimalism is the point.** Before adding a plugin, ask: does Neovim already do this
   natively (folding, commenting via `gc`, LSP hover/rename/references), or does an existing
   plugin already cover it? Don't add a plugin for marginal convenience. Don't add "nice to have"
   config for features nobody asked for. A plugin is justified only if (a) it does something
   natively impossible, or (b) a hand-rolled native replacement would be a real net loss (e.g.
   blink.cmp's precompiled fuzzy matcher beats any completefunc glue code you'd write). This
   config has already been through one such audit: `mini.statusline`/`mini.icons` were replaced
   by `lua/config/statusline.lua` (`vim.o.statusline` + a render function), and
   `toggleterm.nvim` by `lua/config/terminal.lua` (`nvim_open_win` + `jobstart(..., {term=true})`).
   Don't reintroduce either without a concrete capability gap driving it. The same logic extends
   to outsourcing: image/SVG/PDF preview (`lua/config/external.lua`) shells out to `kitten icat`
   or `xdg-open`/`open` rather than pulling in an image-rendering plugin. Before adding a plugin
   for "view/preview X," check whether a CLI tool + the floating terminal
   (`lua/config/terminal.lua`) already covers it.
2. **Documentation is not optional and must not drift.** This repo has a VitePress site under
   `docs/` (user guide) and `docs/decisions/index.md` (a decision log — what was chosen, why, and
   what alternatives were rejected). Whenever a change in this session changes editor *behavior*
   (a keybinding, a plugin added/removed, an LSP setting, a CLI command, a default), update the
   relevant `docs/guide/*.md` page in the same change — not "later." Whenever a change makes a
   non-obvious *choice* (a version pin, cutting a plugin for a native/CLI replacement, picking one
   tool over an equally plausible alternative), add an entry to `docs/decisions/index.md` in the
   same shape as the existing ones: **Decision**, **Context**, **Alternatives considered**, and an
   **Example** if a snippet clarifies it. `README.md`/`KEYBINDINGS.md` at the repo root and the
   `docs/` site cover overlapping ground on purpose — `docs/guide/keybindings.md` includes
   `KEYBINDINGS.md` verbatim via `<!--@include:-->` specifically so that one never drifts from the
   other; don't duplicate that content by hand anywhere else. Before merging any change, ask: does
   a doc page reference something this change just renamed, removed, or contradicted?
3. **`lua/config/keymaps.lua` is the single source of truth for keybindings.** No which-key or
   similar popup plugin — ever. New keybindings go in that one file, grouped under the existing
   section headers, with a `desc` on every mapping (this is what makes `<leader>?` / fzf-lua's
   keymap picker useful — it reads `desc`). Update `KEYBINDINGS.md` to match whenever
   `keymaps.lua` changes; it's documentation, not the source of truth, and drifting is a bug.
4. **Prefer native Neovim APIs over plugin frameworks.** LSP servers are enabled with
   `vim.lsp.config()` / `vim.lsp.enable()` (Neovim 0.11+), never `require('lspconfig').setup{}`
   (deprecated upstream, shows warnings). Check `:h lsp-config` when in doubt.
5. **This ecosystem moves fast — verify, don't assume from training data.** Plugins referenced
   here (blink.cmp, nvim-treesitter, mason-lspconfig, codecompanion.nvim) have had recent breaking
   rewrites and org transfers (e.g. `mini.nvim` moved from `echasnovski` → `nvim-mini`,
   `mason.nvim`/`mason-lspconfig.nvim` moved from `williamboman` → `mason-org`, blink.cmp has an
   actively-breaking v2 alongside a stable v1). Before adding or upgrading a plugin, check its
   current README/source on GitHub (`gh api repos/<owner>/<repo>/contents/README.md -q .content
   | base64 -d`) rather than trusting memorized APIs. This config intentionally pins
   `blink.cmp` to `version = "1.*"` and `nvim-treesitter` to `branch = "master"` for exactly this
   reason — confirm those pins are still the right call before changing them.
6. **Never hardcode secrets.** API keys live in `~/.config/nvim-min/user/secrets.env`, written by
   `nvim-min-setup ai` and loaded into the environment by
   `require("config.user_settings").load_secrets()` (called first thing in `init.lua`, before
   plugins load). `user/` is gitignored — never commit a key, and never add a code path that
   would put one in a tracked file.
7. **Config must survive being deleted or corrupted.** `lua/config/user_settings.lua` always
   falls back to sane defaults if `user/settings.json` is missing or fails to parse — never make
   a plugin's config *require* that file to exist. `nvim-min-setup reset` exists to make "get
   back to defaults" an explicit action, but the implicit fallback is the real safety net and
   must keep working even if that command is never run.
8. **Feature toggles should have real teeth.** When a capability is CLI-disabled
   (`nvim-min-setup features`), the corresponding plugin's lazy.nvim spec should get
   `enabled = false` — not just have its functionality silently skipped at runtime. Disabled means
   "doesn't load," a real startup-cost saving, not a hidden no-op (see `lua/plugins/ai.lua`).
   Anything in `keymaps.lua` that calls into a togglable plugin (e.g. the `<Tab>` ghost-text
   handler) must `pcall(require, ...)` around it, since the module genuinely won't exist when
   disabled.
9. **Headless Neovim skips things you'd expect to just work.** `mason-lspconfig`'s automatic
   install checks `#vim.api.nvim_list_uis() == 0` and silently no-ops under `--headless` — every
   plugin that's lazy-loaded on a file-open event (`nvim-lspconfig` on `BufReadPre`,
   `nvim-treesitter` on `BufReadPost`) also never loads in a headless session with no file buffer
   open, so their commands/functions aren't even registered. `install.sh`'s bootstrap works around
   both by force-loading plugins directly (`require("lazy").load({ plugins = {...} })`) before
   calling their install functions — see `docs/decisions/index.md#install-script`. Keep this in
   mind before assuming a headless test proves something works; verify against a real interactive
   launch (or the same force-load trick) for anything gated on lazy-loading or UI presence.
10. **`mason-lspconfig`'s `automatic_enable` isn't scoped to `ensure_installed`.** It scans *every*
   installed Mason package and auto-enables any that also happen to have an `nvim-lspconfig`
   entry — which is how `stylua` (installed only as a conform.nvim formatter) ended up silently
   attached as a redundant LSP client on every Lua buffer (`stylua --lsp`). Fixed with
   `automatic_enable = { exclude = { "stylua" } }` in `lua/plugins/lsp.lua`. If you add a
   Mason-installed formatter/tool, check whether `nvim-lspconfig` also ships an `lsp/<name>.lua`
   for it before assuming it's formatter-only.
11. **Keep LSP servers fast.** `update_in_insert = false`, disabled LSP semantic tokens (treesitter
   already highlights — see the `LspAttach` callback in `lua/plugins/lsp.lua`), opt-in inlay
   hints (`<leader>ch`, off by default), and pared-down `vtsls` inlay hint kinds all exist for a
   reason. If you add a server, don't regress this — test on a real TypeScript file, not just
   that it attaches (and check `vim.lsp.get_clients()` for anything *unexpected* attaching too —
   see principle #10). Before adding another "speed" tweak, check whether Neovim core already does
   it (e.g. `flags.debounce_text_changes` already defaults to 150ms, and
   `vim/lsp/_watchfiles.lua` already excludes `node_modules`/`.git/objects` from polling) —
   verify in `$VIMRUNTIME/lua/vim/lsp/` before adding config for something core already handles.

## Structure

```
install.sh                    fresh-clone bootstrap: system deps, PATH/alias wiring, nvim
                               bootstrap, offers to launch nvim-min-setup at the end
package.json, node_modules/    deps for bin/nvim-min-setup ONLY (@clack/prompts, picocolors) —
                               gitignored node_modules, installed by install.sh; nvim never
                               touches this
init.lua                    leader keys → load_secrets() → config.options → config.lazy →
                             config.keymaps → config.autocmds, in that order (order matters:
                             secrets must be in the env before any plugin spec evaluates;
                             lazy needs mapleader set first; keymaps need plugins registered
                             so lazy-loading `keys = {...}` specs work)
bin/
  nvim-min-setup               the config CLI (Node + @clack/prompts) — see decoupling note above
  nvims                        nvm-style picker across every ~/.config/nvim* config
lua/config/
  options.lua                 vim.opt, disabled built-ins/providers, diagnostics/fold config
  keymaps.lua                 ALL keybindings (see principle #2)
  autocmds.lua                 general-purpose autocmds only — LSP-attach keymaps/autocmds live
                               in lua/plugins/lsp.lua's config() function, next to the LSP setup
                               they depend on
  lazy.lua                    lazy.nvim bootstrap
  statusline.lua               native statusline, no plugin (see principle #1)
  terminal.lua                 native floating terminal + LazyGit, no plugin (see principle #1)
  external.lua                 outsources file preview to kitten icat / xdg-open (see principle #1)
  user_settings.lua            reads user/settings.json + user/secrets.env; DEFAULTS table here
                               must stay in sync with DEFAULT_SETTINGS in bin/nvim-min-setup
lua/plugins/*.lua              one file per concern, each returning a lazy.nvim plugin spec
                               (or list of specs) — colorscheme.lua and ai.lua read
                               user_settings at spec-evaluation time to set theme/enabled
user/                         gitignored, machine-local — settings.json + secrets.env
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
- **Add a formatter**: add to `formatters_by_ft` in `lua/plugins/formatting.lua`, and to the
  `mason_ensure_installed({...})` call in `lua/plugins/lsp.lua` if it's not already installed as
  an LSP server package (that function is a direct `mason-registry` call, not a plugin — see
  principle #1).
- **Add a keybinding**: `lua/config/keymaps.lua` only, with a `desc`. Mirror it in
  `KEYBINDINGS.md`.
- **Add a plugin**: justify it against principle #1 first. If it's genuinely needed, add a new
  `lua/plugins/<concern>.lua` file (or extend an existing one if it fits an existing concern) —
  don't dump unrelated plugins into one file.
- **Add a CLI-configurable feature toggle** (à la `features.ghost_text`): add the key + default
  to both the `DEFAULTS` object in `lua/config/user_settings.lua` *and* the `DEFAULTS` object in
  `bin/nvim-min-setup` (they must match — nothing enforces this automatically), add it as an
  option in `cmdFeatures()`'s `multiselect` in the CLI, and gate the plugin's lazy spec with
  `enabled = require("config.user_settings").load().features.<name>` (see principle #7 and
  `lua/plugins/ai.lua` for the pattern).
