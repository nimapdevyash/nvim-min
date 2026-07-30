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
CLI, built with `@clack/prompts`, that owns all interactive setup: AI provider + API key, theme,
feature toggles, plus a `doctor` diagnostic command). Don't blur this line by adding interactive
prompts, settings UIs, or setup wizards to the Lua side — that belongs in the CLI, which is
allowed to have dependencies and complexity the editor itself isn't. `install.sh` at the repo
root is the third piece: a bootstrap script that detects the OS/package manager, installs system
requirements, wires up `nvim-min-setup`/`nvims`, and bootstraps nvim itself on a fresh clone. All
three are independent — nvim never imports, shells out to, or waits on either of the other two at
runtime. Both `install.sh` and `nvim-min-setup` log every run to `~/.cache/nvim-min/` — see "Logs
& debugging" below before assuming something failed silently.

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
   section headers, with a `desc` on every mapping. Update `KEYBINDINGS.md` to match whenever
   `keymaps.lua` changes; it's documentation, not the source of truth, and drifting is a bug.
   `<leader>?`/`<leader>k` / the dashboard's `k` action (`lua/config/keymap_search.lua`) are a **different**
   case: they regenerate a key→description list from the live keymap registry
   (`vim.api.nvim_get_keymap`) fresh every time they're opened, rather than reading a hand-written
   file — so there is nothing to keep in sync there, by design (see
   `docs/decisions/index.md#keymap-search-txt-export`). Don't add a manual-sync step for it; if a
   new keymap ever doesn't show up in that search, the bug is a missing/empty `desc` on the mapping
   itself, not a stale export.
4. **Prefer native Neovim APIs over plugin frameworks.** LSP servers are enabled with
   `vim.lsp.config()` / `vim.lsp.enable()` (Neovim 0.11+), never `require('lspconfig').setup{}`
   (deprecated upstream, shows warnings). Check `:h lsp-config` when in doubt.
5. **This ecosystem moves fast — verify, don't assume from training data.** Plugins referenced
   here (blink.cmp, nvim-treesitter, mason-lspconfig, codecompanion.nvim) have had recent breaking
   rewrites and org transfers (e.g. `mini.nvim` moved from `echasnovski` → `nvim-mini`,
   `mason.nvim`/`mason-lspconfig.nvim` moved from `williamboman` → `mason-org`, blink.cmp has an
   actively-breaking v2 alongside a stable v1). Before adding or upgrading a plugin, check its
   current README/source on GitHub (`gh api repos/<owner>/<repo>/contents/README.md -q .content
   | base64 -d`) rather than trusting memorized APIs. This config intentionally pins `blink.cmp`
   to `version = "1.*"` for exactly this reason — confirm that pin is still the right call before
   changing it. `nvim-treesitter` was *also* pinned to `master` at first for the same reasoning
   (avoid the actively-changing rewrite) — that turned out wrong in practice: `master`'s bundled
   queries don't reliably match its own parsers on Neovim 0.12, causing a real crash
   (`attempt to call method 'range' (a nil value)` opening any `.html` file). Now on `main`, which
   needs a genuine `tree-sitter-cli` 0.26+ (`install.sh` handles it via brew). See
   `docs/decisions/index.md#treesitter-main` for the full story — the lesson isn't "pin less," it's
   "verify a pin is still correct when something breaks, don't assume the original reasoning still
   holds."
6. **Never hardcode secrets, and never let one reach a log or a URL.** API keys (`GEMINI_API_KEY`/
   `OPENAI_API_KEY`/`ANTHROPIC_API_KEY` — three independent providers, see #multi-provider-ai)
   live in `~/.config/nvim-min/user/secrets.env`, written by `nvim-min-setup ai` and loaded into
   the environment by `require("config.user_settings").load_secrets()` (called first thing in
   `init.lua`, before plugins load). `user/` is gitignored — never commit a key, and never add a
   code path that would put one in a tracked file. This extends to the CLI's own debug log
   (`~/.cache/nvim-min/setup-cli.log`, see "Logs & debugging") — a `logLine` call must never pass
   a raw key value, only that an event happened (provider + key length, never the string). Prefer
   an HTTP header over a URL query parameter for a key in any new `verify()`-style network call —
   Gemini's key was moved off `?key=` specifically because a URL is a more likely place for a
   secret to leak (network-error messages, proxy logs) than a header.
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

This section is meant to be a complete, accurate map — if you add, remove, or repurpose a file,
update this section in the same change. It drifting is exactly the kind of thing principle #2
warns about, just applied to this file instead of the `docs/` site.

```
install.sh                    fresh-clone bootstrap: detects OS/package manager (prefers each
                               distro's own where it's good enough — pacman on Arch for
                               tree-sitter-cli/lazygit/Neovim itself, brew elsewhere — see
                               #arch-native-packages), PATH/alias wiring into every shell rc
                               file present (not one guessed from $SHELL, see
                               #shell-agnostic-install), nvim bootstrap, offers to launch
                               nvim-min-setup at the end. Logs its full transcript to
                               ~/.cache/nvim-min/install.log every run (see "Logs & debugging"
                               below) — an ERR trap reports the exact step/command/line on failure.
package.json, node_modules/   deps for bin/nvim-min-setup ONLY (@clack/prompts, picocolors) —
                               gitignored node_modules, installed by install.sh; nvim never
                               touches this
init.lua                      leader keys → load_secrets() → config.options → config.lazy →
                               config.keymaps → config.autocmds, in that order (order matters:
                               secrets must be in the env before any plugin spec evaluates;
                               lazy needs mapleader set first; keymaps need plugins registered
                               so lazy-loading `keys = {...}` specs work)
bin/
  nvim-min-setup               the config CLI (Node + @clack/prompts) — see decoupling note above.
                               Also logs every invocation to ~/.cache/nvim-min/setup-cli.log —
                               never a key's actual value, only that an event happened (see
                               "Logs & debugging")
  nvims                        nvm-style picker across every ~/.config/nvim* config
lua/config/
  options.lua                  vim.opt, disabled built-ins/providers, diagnostics/fold config
  keymaps.lua                  ALL keybindings (see principle #3)
  keymap_search.lua            backs `<leader>?`/`<leader>k` and the dashboard's `k` — regenerates a plain
                                key→description list from the live keymap registry every time
                                it's opened, plus writes it to a real .txt file for browsing
                                outside nvim (see principle #3 and #keymap-search-txt-export)
  autocmds.lua                  general-purpose autocmds only — LSP-attach keymaps/autocmds live
                                in lua/plugins/lsp.lua's config() function, next to the LSP setup
                                they depend on
  lazy.lua                     lazy.nvim bootstrap
  statusline.lua                native statusline, no plugin (see principle #1)
  terminal.lua                  native floating terminal + LazyGit, no plugin (see principle #1)
  dashboard.lua                  native start screen (scratch buffer + vim.v.oldfiles + git-root
                                detection for "recent projects"), no plugin (see principle #1)
  harpoon.lua                   numbered file marks, persisted per-project to
                                stdpath("state"), no plugin (see principle #1)
  external.lua                  outsources file preview to kitten icat / xdg-open (see principle #1)
  user_settings.lua             reads user/settings.json + user/secrets.env; DEFAULTS table here
                                must stay in sync with DEFAULTS in bin/nvim-min-setup AND
                                lua/plugins/ai.lua's expectations — three places, nothing
                                enforces agreement automatically. `ai_provider` is
                                `{chat=..., ghost_text=...}` (per-feature, not one global
                                choice) — a plain-string old shape is migrated on load, on
                                both the Lua and CLI sides independently.
lua/plugins/*.lua              one file per concern, each returning a lazy.nvim plugin spec
                                (or list of specs):
  editor.lua                    snacks.nvim (explorer + picker + notifier — see below),
                                mini.icons, mini.pairs, mini.surround
  lsp.lua                       nvim-lspconfig, mason.nvim/mason-lspconfig, all per-server
                                config and LspAttach keymaps
  completion.lua                blink.cmp (pinned 1.*)
  formatting.lua                conform.nvim
  git.lua                       gitsigns.nvim
  treesitter.lua                nvim-treesitter (main branch, needs tree-sitter-cli 0.26+)
  colorscheme.lua                onedark.nvim; also fixes onedark's own incomplete
                                `transparent` option (NormalFloat/FloatBorder/Pmenu never
                                checked it upstream — see #float-transparency)
  ui.lua                        noice.nvim (floating cmdline/messages) — `routes` sends
                                ERROR-level notify calls to a distinct, prominent view
                                instead of the same easy-to-miss popup as routine info (see
                                #noice-error-prominence; needs editor.lua's
                                `notifier = {enabled = true}` to actually work, not just the
                                route existing)
  markdown.lua                   render-markdown.nvim, lazy-loaded on ft=markdown
  ai.lua                        codecompanion.nvim (chat) + minuet-ai.nvim (ghost text) —
                                provider-agnostic, reads `ai_provider.chat`/`.ghost_text`
                                independently (see #multi-provider-ai)
user/                          gitignored, machine-local — settings.json + secrets.env
docs/                          VitePress site — docs/index.md, docs/guide/*.md (one page per
                                topic), docs/decisions/index.md (the decision log, see
                                principle #2)
```

## How to test a change

There's no test suite — this is an editor config. Headless Neovim catches syntax/load errors but
**does not prove a specific keybinding resolves to a specific implementation** — that gap
produced a real, shipped regression (see `#keymaps-stale-regression`): `lua/config/keymaps.lua`
was stuck calling `fzf-lua`/`<cmd>Oil<cr>` (neither installed anymore) for over a dozen
keybindings, and `bash -n`/`node --check`/a headless `nvim --headless -c quit` all passed the
entire time, because none of them execute a mapping's actual `rhs`. The only thing that caught it
was a real interactive session and `:verbose map <key>`.

```sh
NVIM_APPNAME=nvim-min nvim --headless -c "quit"          # catches syntax/load errors ONLY
NVIM_APPNAME=nvim-min nvim path/to/real-file.ts           # open a real file, check :LspInfo,
                                                           # :checkhealth vim.lsp, that gd/K/<leader>ca
                                                           # actually work
```

**For anything touching keybindings, plugin removal/replacement, or a toggle/UI interaction**,
verify with a real interactive session, not just headless — a detached `tmux` session is the
practical way to do this without a human at a keyboard:

```sh
tmux new-session -d -s t -x 200 -y 50
tmux send-keys -t t "NVIM_APPNAME=nvim-min nvim" Enter
sleep 2
tmux send-keys -t t "<the actual key sequence you're testing>"
sleep 1
tmux capture-pane -t t -p                 # read back what's actually on screen
tmux send-keys -t t ":verbose map <key>" Enter   # confirm WHICH script last set a mapping,
tmux capture-pane -t t -p                        # not just that *a* mapping exists
tmux kill-session -t t
```

`:verbose map <lhs>` is the single most useful command here — it shows the exact `rhs` and which
file last set it, which is what actually caught the regression above (`:verbose map -` showed
`<Cmd>Oil<CR>`, "Last set from init.lua", when it should have shown a `snacks.explorer()`
callback). A `pcall`/API-level headless check (e.g. calling `Snacks.explorer()` directly from a
`luafile`) only proves the underlying library call works — it does not prove `keymaps.lua` is
correctly wired to call it, which is exactly where this regression lived.

When changing `lua/plugins/lsp.lua`, test against real `.ts`/`.py`/`.tf` files, not empty
buffers — inlay hints, eslint autofix-on-save, and schema validation only show up with real
content.

**When splitting a large uncommitted diff into micro-commits** (reconstructing an intermediate
file state to isolate one change from another), the working tree ending up correct is a *separate*
claim from the diff looking correct — `git add`/`git commit` succeeding proves neither. After any
such reconstruction, diff the final committed state of every touched file against what you
believe the true final content should be (`git show HEAD:path | diff - <expected>`, or at minimum
re-grep the whole repo for the specific strings the change was supposed to remove), not just that
each individual commit's diff looked sensible in isolation.

## Logs & debugging

Both `install.sh` and `nvim-min-setup` write a full, real transcript on every run — check these
before assuming something failed silently or asking the user to describe what happened:

- `~/.cache/nvim-min/install.log` — `install.sh`'s complete output (this script's own messages
  and every subcommand's — `npm install`, `pacman`/`apt-get`, the headless nvim bootstrap),
  overwritten fresh each run, preceded by a header (`uname`, `/etc/os-release`, user, shell). On
  failure, the script's own `ERR` trap already reports the exact step/command/line — the log has
  everything around that point too.
- `~/.cache/nvim-min/setup-cli.log` — `nvim-min-setup`'s append-only log: which command ran, every
  `settings.json` write, every API key set/cleared (provider + key **length** only, never the
  value), key-verification results, `doctor`'s full results, and any uncaught error's full stack
  trace (the terminal only ever shows a short version). **Never grep this file expecting to find
  an actual key** — that's a deliberate invariant, not an oversight; if you're adding a new
  `logLine` call, it must never pass a raw secret value through.
- `nvim-min-setup doctor` — the fastest way to check system state without reading a log at all:
  system requirements (mirroring what `install.sh` installs) plus a **live verification of every
  stored API key** (a fast offline format check, then a real request to the provider). This is
  what should be run first for any "ghost text/chat doesn't work" report — it once took a full
  interactive session tracing `vim.env.GEMINI_API_KEY` by hand to find a malformed key that
  `doctor` now catches in one command (see `#doctor-key-verification`).
- `~/.local/state/nvim-min/nvim-min/errors.log` — every ERROR/WARN that passes through
  `vim.notify` inside Neovim itself (plugin errors, LSP client notices, AI provider failures),
  append-only, full message text. Separate from the two logs above, which only cover the shell
  installer and the setup CLI — this one's for runtime problems *inside* the editor. Open it
  quickly with `:NvimMinErrors`. See `lua/config/error_log.lua` and
  `#centralized-error-log` for why this hooks noice.nvim's message manager instead of `vim.notify`
  directly once noice loads (wrapping `vim.notify` itself after noice takes it over triggers
  noice's own watchdog, which treats that as a misconfigured-plugin bug and complains loudly,
  repeatedly).

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
  `enabled = require("config.user_settings").load().features.<name>` (see principle #8 and
  `lua/plugins/ai.lua` for the pattern).
