# nvim-min

A from-scratch, minimal, fast Neovim config for **MERN + DevOps + Gen AI** work. Built to sit
*alongside* your existing config (e.g. LazyVim), not replace it — see [Switching configs](#switching-configs).

**Full user guide + a decision history explaining every non-obvious choice: [`docs/`](docs/)**
(VitePress). Run it locally with:

```sh
cd docs && npm install && npm run dev
```

This README stays as the quick-reference version; `docs/` is the thorough one.

## Philosophy

- **Every plugin earns its place.** Before a plugin goes in, the question is: can Neovim already
  do this natively, well enough? If yes, it's out. A plugin only survives if it does something
  natively impossible (git gutters, fuzzy install of LSP binaries, Gemini access) — or does it so
  much better than a hand-rolled native replacement that reimplementing it would be a net loss
  (blink.cmp's precompiled fuzzy matcher is faster than any completefunc glue code could be).
  Statusline, floating terminal, and file-type icons went the other way: pure Lua and
  `nvim_open_win`/`vim.o.statusline` cover them fully, so no plugin exists for those anymore.
- **Native APIs over frameworks.** LSP servers are wired with `vim.lsp.config()` /
  `vim.lsp.enable()` (Neovim 0.11+ core API), not the legacy `require('lspconfig').setup{}` wrapper.
- **One file for keybindings.** No which-key popup — see [KEYBINDINGS.md](KEYBINDINGS.md) and
  [`lua/config/keymaps.lua`](lua/config/keymaps.lua). Search live keymaps with `<leader>?`.
- **Lazy-load everything that can be.** Startup should stay near-instant as the config grows.
- **Configuration is decoupled from the editor.** nvim-min never prompts you for anything at
  runtime — no in-editor settings UI, no setup wizard. All of that lives in
  [`nvim-min-setup`](#configuration-cli-nvim-min-setup), a separate CLI that's allowed to be as
  batteries-included as it wants (it's a real Node CLI with `@clack/prompts`, not a shell script
  squeezed for size) precisely because it's not part of what loads when you open a file.

## Requirements

Handled for you by [`install.sh`](#one-command-setup-installsh) if missing — listed here for
reference:

- Neovim **0.12+**
- `git`, `curl`, `tar`, a C compiler (`cc`) — for building treesitter parsers
- [`fzf`](https://github.com/junegunn/fzf), [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fuzzy finding / grep
- [`lazygit`](https://github.com/jesseduffield/lazygit) — `<leader>gg`
- `node` + `npm` — most LSP servers/formatters install through Mason via npm; also runs the setup CLI
- Python's `venv` module (on Debian/Ubuntu, a separate `python3-venv` package) — needed for the
  Python LSP servers (`basedpyright`, `ruff`) to install via Mason
- A [Gemini API key](https://aistudio.google.com/apikey) for the AI features (optional, set up below)

Everything else (language servers, formatters, treesitter parsers) installs itself via
[mason.nvim](https://github.com/mason-org/mason.nvim) / `:TSUpdate` — `install.sh` triggers this
too, so it's already done by the time you first open nvim.

## One-command setup (`install.sh`)

```sh
git clone https://github.com/nimapdevyash/nvim-min ~/.config/nvim-min
cd ~/.config/nvim-min && ./install.sh
```

This does everything: detects your OS/package manager and installs whatever's missing from the
requirements above, symlinks `nvim-min-setup`/`nvims` onto your `PATH`, wires the `nv` alias into
your shell rc (idempotently — safe to re-run), bootstraps nvim itself (plugins, LSP servers,
treesitter parsers — genuinely takes a few minutes the first time), and finishes by offering to
launch the interactive setup CLI right then. See
[Decision history → One-command setup](docs/decisions/index.md#install-script) for why it's structured this way.

Then launch with `nv`, or `NVIM_APPNAME=nvim-min nvim` directly, or the `nvims` picker below.

## Configuration CLI (`nvim-min-setup`)

nvim-min itself is deliberately dumb about configuration: it reads two files at startup and
otherwise doesn't ask you anything. All the interactive setup — the part that's allowed to be as
"fully loaded" as it wants without slowing the editor down — lives in a separate tool,
[`bin/nvim-min-setup`](bin/nvim-min-setup) (symlinked to `~/.local/bin/nvim-min-setup` by
`install.sh`). It's a small Node CLI built with
[`@clack/prompts`](https://github.com/bombshell-dev/clack) — the same kind of polished,
arrow-key-navigable experience as `npm create vite@latest` — not a bash script, precisely because
this tool is explicitly allowed to have dependencies and a real UI that nvim itself isn't.

```
nvim-min-setup            interactive menu
nvim-min-setup ai         set your Gemini API key
nvim-min-setup theme      pick a onedark style + transparency
nvim-min-setup features   turn AI ghost-text / AI chat on or off — disabled
                          features don't just no-op, they don't load at all
                          (lazy.nvim `enabled = false`, a real startup-time saving)
nvim-min-setup status     show current settings (never prints the key back)
nvim-min-setup reset      restore theme/feature settings to defaults
```

It writes two gitignored files under `~/.config/nvim-min/user/` (never committed, `chmod 600`):

- `settings.json` — theme, transparency, feature toggles. Read by `lua/plugins/colorscheme.lua`
  and `lua/plugins/ai.lua` at startup.
- `secrets.env` — `GEMINI_API_KEY=...`. Loaded into the environment by
  `lua/config/user_settings.lua` before any plugin runs, so codecompanion and minuet-ai just see
  it as if it were exported normally.

**This is deliberately hard to break permanently.** If `settings.json` goes missing or gets
corrupted, `lua/config/user_settings.lua` falls back to the same built-in defaults the CLI ships
with — nvim never fails to start over a bad settings file. `nvim-min-setup reset` makes that
explicit and intentional instead of relying on the implicit fallback.

## Switching configs

Neovim's native [`NVIM_APPNAME`](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME) env var
picks a completely isolated config: its own `~/.config/<name>`, `~/.local/share/<name>`,
`~/.local/state/<name>`, and cache dir. Nothing here touches your existing LazyVim config at
`~/.config/nvim` — they're fully independent installs.

Three ways to jump between them:

1. **`nvims`** — an `nvm`-style interactive picker (`~/.local/bin/nvims`, on `PATH`). Run `nvims`
   with no args to fuzzy-pick a config (fzf UI with a README preview pane), or `nvims nvim-min` /
   `nvims nvim` to jump straight to one.
2. **Shell aliases** (added to `~/.zshrc`):
   - `nvim` → unchanged, your existing LazyVim config
   - `nv` → this config (`NVIM_APPNAME=nvim-min nvim`)
3. Set `NVIM_APPNAME` manually for one-off scripting/CI use.

Adding a third config later (e.g. a stripped-down `nvim-writing`) is just another directory under
`~/.config/nvim*` — `nvims` picks it up automatically, no changes needed here.

## What's in it, and why

12 plugins total, two of them individually disableable at zero startup cost from the CLI (see
below). Every plugin here does something native Neovim genuinely can't, or does it enough better
that reimplementing it natively would be a net loss — noted per row.

| Concern | Plugin | Why a plugin, not native |
|---|---|---|
| Plugin manager | [lazy.nvim](https://github.com/folke/lazy.nvim) | No native equivalent for lazy-loading + lockfile |
| Theme | [onedark.nvim](https://github.com/navarasu/onedark.nvim) (dark, transparent) | Neovim ships no built-in Atom One Dark colorscheme, let alone one with a `transparent` option |
| Treesitter | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`main` branch) | Neovim's treesitter *engine* is native; parser/query installation isn't. Needs `tree-sitter-cli` 0.26+ (`brew install tree-sitter-cli`) — `install.sh` handles this. `master` was tried first for a lower-dependency install, but its queries don't reliably match its own parsers on Neovim 0.12 (a real crash, not a caveat — see decision history) |
| LSP client config | [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Hand-maintaining `cmd`/`filetypes`/`root_markers` for 14 servers ourselves is pure duplicated upkeep for zero benefit; this is data, consumed by native `vim.lsp.config` |
| LSP/tool installer | [mason.nvim](https://github.com/mason-org/mason.nvim) + mason-lspconfig | No native installer for external LSP binaries. (`mason-tool-installer` was cut — its whole job is ~10 lines against `mason-registry`, done directly in `lua/plugins/lsp.lua`) |
| Completion | [blink.cmp](https://github.com/saghen/blink.cmp) (`1.*`) | Neovim 0.11+ *can* do native LSP-driven completion (`vim.lsp.completion.enable`), but merging LSP+path+buffer into one fuzzy-ranked list needs real glue code, and blink's precompiled matcher (0.5–4ms/keystroke) would beat a hand-rolled version anyway. Pinned to stable `1.*` — v2 is an active rewrite needing an extra `blink.lib` dependency |
| Formatting | [conform.nvim](https://github.com/stevearc/conform.nvim) | `vim.lsp.buf.format()` alone only formats via whatever the LSP server implements — vtsls's formatting is far weaker than prettier, and eslint's LSP doesn't format at all |
| Git signs | [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | No native git gutter/hunk/blame support |
| Fuzzy finder | [fzf-lua](https://github.com/ibhagwan/fzf-lua) | No native fuzzy-match UI; uses the `fzf` binary directly, lighter than Telescope |
| File manager | [oil.nvim](https://github.com/stevearc/oil.nvim) | Native netrw exists but is slow and clunky; oil is small and meaningfully better |
| Pairs/surround | [mini.pairs](https://github.com/nvim-mini/mini.pairs) / [mini.surround](https://github.com/nvim-mini/mini.surround) | No native auto-pairs or surround-text-object support |
| AI chat (Gemini) | [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) | The whole point — no native LLM integration exists. Toggle: `nvim-min-setup features` |
| AI ghost text (Gemini) | [minuet-ai.nvim](https://github.com/milanglacier/minuet-ai.nvim) | Copilot-style inline suggestions; needs its own provider glue no native completion has. Toggle: `nvim-min-setup features` |

**Replaced with native Neovim, no plugin at all:**

| Used to be | Now | See |
|---|---|---|
| mini.statusline + mini.icons | `vim.o.statusline` + a ~40-line render function, no icon font | [`lua/config/statusline.lua`](lua/config/statusline.lua) |
| toggleterm.nvim | `nvim_open_win` + `jobstart(cmd, {term=true})`, ~50 lines, same "toggle keeps the process alive" behavior | [`lua/config/terminal.lua`](lua/config/terminal.lua) |
| mason-tool-installer.nvim | Direct `mason-registry` calls | `lua/plugins/lsp.lua` |
| alpha.nvim / dashboard.nvim / snacks dashboard | A scratch buffer + `vim.v.oldfiles`, ~180 lines | [`lua/config/dashboard.lua`](lua/config/dashboard.lua) |
| harpoon.nvim | JSON file per project (`stdpath("state")`) + `fzf-lua.fzf_exec` for the searchable list, ~100 lines | [`lua/config/harpoon.lua`](lua/config/harpoon.lua) |
| which-key.nvim | `keymaps.lua` + `<leader>?` (fzf-lua's live keymap picker) | [KEYBINDINGS.md](KEYBINDINGS.md) |
| Comment.nvim | Neovim's built-in `gc`/`gcc` | — |
| indent-blankline.nvim | Not replaced — just cut. Visual only, and repaints on every cursor move | — |
| nvim-tree / neo-tree | oil.nvim (see table above — still a plugin, just a smaller/faster one than netrw-replacements usually are) | — |

## Performance notes (Zed-inspired)

Zed's speed comes from doing LSP/indexing work off the UI thread and being disciplined about
what triggers it. The Neovim-native equivalents applied here:

- **No duplicate highlighting work.** LSP semantic tokens are explicitly disabled on attach
  (`client.server_capabilities.semanticTokensProvider = nil` in `lua/plugins/lsp.lua`) —
  treesitter already highlights syntax, so semantic tokens would just redo that per edit for
  servers like vtsls/eslint, for little extra benefit.
- **Inlay hints are opt-in, not on by default.** They cost an LSP request per visible range on
  every scroll/edit on large files. Toggle with `<leader>ch`.
- **Diagnostics don't recompute on every keystroke** (`update_in_insert = false`).
- **Text-change notifications are debounced 150ms** — this is actually Neovim's own default
  (`flags.debounce_text_changes`), not something added here; confirmed by reading
  `vim/lsp/_changetracking.lua` rather than assumed.
- **File-watching exclusions**: also already handled by Neovim core (`vim/lsp/_watchfiles.lua`
  excludes `node_modules/*/**`, `.git/objects`, `.hg/store` from polling by default) — checked,
  and deliberately *not* re-implemented or disabled wholesale, since doing so would cost real
  features (e.g. eslint reacting to config file changes) for gain Neovim already provides.
- **vtsls inlay hint kinds are pared down** in its settings (only parameter names on literals) —
  the rest cost more to compute than they're worth day-to-day.
- Mason-installed binaries are cached on disk after first install — nothing to "warm up" on
  every launch.

## AI ghost text

`minuet-ai.nvim` shows Gemini-generated inline suggestions as you type (Copilot-style), for
`javascript`/`typescript`/`(t|j)sx`, `python`, `lua`, `sh`, `yaml`, `dockerfile`, `terraform`,
`json`, `html`, `css` — the languages this config targets, not every filetype.

| Key | Action |
|---|---|
| `<Tab>` | Accept the whole suggestion — falls through to blink.cmp's normal `<Tab>` (menu-select/snippet-jump/indent) when no ghost text is showing |
| `<A-a>` | Accept one line only |
| `<A-z>` | Accept N lines (prompts for a count) |
| `<A-]>` / `<A-[>` | Cycle to next / previous suggestion |
| `<A-e>` | Dismiss |
| `<leader>at` | Toggle ghost text for this session only |

`<leader>at` and `nvim-min-setup features` are two different levers on purpose: `<leader>at` is
"I don't want suggestions for the next 10 minutes"; the CLI toggle is "I don't want this plugin
loaded at all" (persists across restarts, skips loading it entirely — a real startup-time saving,
not just a hidden no-op).

## Outsourcing instead of plugins

Some things are better delegated to a real terminal tool or the OS than reimplemented as an nvim
plugin — image.nvim and friends need a rendering backend, extra deps, and redraw-on-scroll
overhead just to show a PNG. Instead: `<leader>ox` shells out to `xdg-open`/`open` (whatever your
OS already has configured) and `<leader>oi` renders inline in a floating terminal via
[kitty's `icat`](https://sw.kovidgoyal.net/kitty/kittens/icat/) if installed. Both live in
[`lua/config/external.lua`](lua/config/external.lua) — ~50 lines, zero nvim-side rendering code,
zero cost when not invoked. This is the general pattern for anything similar going forward: reach
for a CLI tool + the floating terminal (`lua/config/terminal.lua`) before reaching for a plugin.

## LSP servers configured

TypeScript/JS: `vtsls` (faster, more feature-complete than `ts_ls` for large projects) + `eslint`
(auto-fixes on save) · Web: `html`, `cssls`, `tailwindcss` · Data: `jsonls`, `yamlls` (both with
[SchemaStore](https://www.schemastore.org/) validation) · Lua: `lua_ls` · Python (Gen AI work):
`basedpyright` + `ruff` · DevOps: `bashls`, `dockerls`, `docker_compose_language_service`,
`terraformls` · Docs: `marksman`.

Formatters (conform.nvim): `prettierd` (JS/TS/JSON/YAML/HTML/CSS/MD), `stylua` (Lua), `shfmt`
(shell), `ruff_format` (Python), `terraform_fmt` (requires the `terraform` CLI on `PATH` if you
want it to actually run — install it separately, it's not something Mason manages).

## Directory structure

```
init.lua                    entrypoint: leader keys → load secrets → options → lazy → keymaps → autocmds
bin/
  nvim-min-setup              the config CLI (symlinked to ~/.local/bin) — see Configuration CLI
lua/config/
  options.lua                editor options, disabled built-ins, folding, wires the statusline
  keymaps.lua                ALL keybindings — the single source of truth
  autocmds.lua                general autocmds (not LSP-specific — those live in plugins/lsp.lua)
  lazy.lua                    lazy.nvim bootstrap + performance settings
  statusline.lua              native statusline (no plugin) — see Performance notes
  terminal.lua                native floating terminal + LazyGit (no plugin) — see Performance notes
  user_settings.lua           reads user/settings.json + user/secrets.env, defaults if missing/corrupt
lua/plugins/
  colorscheme.lua, treesitter.lua, lsp.lua, completion.lua, formatting.lua,
  git.lua, editor.lua, ai.lua
user/                        gitignored — settings.json + secrets.env, written by nvim-min-setup
KEYBINDINGS.md                human-readable keymap reference
CLAUDE.md                     guide for AI coding agents contributing to this repo
```

## Adding a new LSP server

1. Add its `nvim-lspconfig` name to `ensure_installed` in `lua/plugins/lsp.lua`.
2. Only add a `vim.lsp.config("name", {...})` block if the defaults genuinely aren't enough —
   most servers need nothing.
