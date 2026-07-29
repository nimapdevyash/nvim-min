# nvim-min

A from-scratch, minimal, fast Neovim config for **MERN + DevOps + Gen AI** work. Built to sit
*alongside* your existing config (e.g. LazyVim), not replace it — see [Switching configs](#switching-configs).

## Philosophy

- **Every plugin earns its place.** No dashboards, no icon-only nice-to-haves, no plugin that
  duplicates something Neovim already does natively (commenting, folding, diagnostics UI).
- **Native APIs over frameworks.** LSP servers are wired with `vim.lsp.config()` /
  `vim.lsp.enable()` (Neovim 0.11+ core API), not the legacy `require('lspconfig').setup{}` wrapper.
- **One file for keybindings.** No which-key popup — see [KEYBINDINGS.md](KEYBINDINGS.md) and
  [`lua/config/keymaps.lua`](lua/config/keymaps.lua). Search live keymaps with `<leader>?`.
- **Lazy-load everything that can be.** Startup should stay near-instant as the config grows.

## Requirements

- Neovim **0.12+**
- `git`, `curl`, `tar`, a C compiler (`cc`) — for building treesitter parsers
- [`fzf`](https://github.com/junegunn/fzf), [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fuzzy finding / grep
- [`lazygit`](https://github.com/jesseduffield/lazygit) — `<leader>gg`
- `node` + `npm` — most LSP servers/formatters install through Mason via npm
- A [Gemini API key](https://aistudio.google.com/apikey) for the AI assistant (optional but the whole point)

Everything else (language servers, formatters, treesitter parsers) installs itself on first
launch via [mason.nvim](https://github.com/mason-org/mason.nvim) / `:TSUpdate`.

## Setup

```sh
export GEMINI_API_KEY="your-key-here"   # add to ~/.zshrc, don't commit it anywhere
```

Then launch with:

```sh
NVIM_APPNAME=nvim-min nvim
```

or use the `nvims` picker / shell aliases below. First launch installs plugins, LSP servers and
treesitter parsers — give it a minute or two, then `:checkhealth vim.lsp` to confirm servers are up.

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

| Concern | Plugin | Why this one |
|---|---|---|
| Plugin manager | [lazy.nvim](https://github.com/folke/lazy.nvim) | Lazy-loading, lockfile, fast |
| Theme | [catppuccin](https://github.com/catppuccin/nvim) (mocha, transparent) | Best-in-class integration highlights, native transparency |
| Treesitter | [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter) (`master` branch) | The `main` rewrite needs a system `tree-sitter-cli` 0.26+; `master` compiles with plain `cc`, zero extra deps |
| LSP client config | [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig) | Ships server definitions consumed by native `vim.lsp.config` |
| LSP/tool installer | [mason.nvim](https://github.com/mason-org/mason.nvim) + mason-lspconfig + mason-tool-installer | Auto-installs servers/formatters, auto-`vim.lsp.enable()`s them |
| Completion | [blink.cmp](https://github.com/saghen/blink.cmp) (`1.*`) | Fastest completion engine available; pinned to stable v1 (v2 is an active rewrite requiring an extra `blink.lib` dependency) |
| Formatting | [conform.nvim](https://github.com/stevearc/conform.nvim) | Async, minimal, format-on-save |
| Git signs | [gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim) | Gutter signs, hunks, blame |
| Fuzzy finder | [fzf-lua](https://github.com/ibhagwan/fzf-lua) | Uses the `fzf` binary directly — faster and lighter than Telescope |
| File manager | [oil.nvim](https://github.com/stevearc/oil.nvim) | Edit the filesystem like a buffer, replaces netrw |
| Pairs/surround/icons/statusline | [mini.nvim](https://github.com/nvim-mini/mini.nvim) modules | One ecosystem, tiny, each module installed independently |
| Terminal / LazyGit | [toggleterm.nvim](https://github.com/akinsho/toggleterm.nvim) | Floating terminal + `<leader>gg` LazyGit |
| AI (Gemini) | [codecompanion.nvim](https://github.com/olimorris/codecompanion.nvim) | Native Gemini adapter, chat + inline assistant, no vendor lock-in |

Deliberately **not** included: which-key (see philosophy above), a dashboard/greeter, indent-guide
plugins (cheap visually, not cheap on every cursor move), a dedicated comment plugin (Neovim's
built-in `gc`/`gcc` already does this), nvim-tree/neo-tree (oil.nvim covers it), Telescope
(fzf-lua is faster for the same job).

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
init.lua                    entrypoint: leader keys, then options → lazy → keymaps → autocmds
lua/config/
  options.lua                editor options, disabled built-ins, folding
  keymaps.lua                ALL keybindings — the single source of truth
  autocmds.lua                general autocmds (not LSP-specific — those live in plugins/lsp.lua)
  lazy.lua                    lazy.nvim bootstrap + performance settings
lua/plugins/
  colorscheme.lua, treesitter.lua, lsp.lua, completion.lua, formatting.lua,
  git.lua, editor.lua, ui.lua, terminal.lua, ai.lua
KEYBINDINGS.md                human-readable keymap reference
CLAUDE.md                     guide for AI coding agents contributing to this repo
```

## Adding a new LSP server

1. Add its `nvim-lspconfig` name to `ensure_installed` in `lua/plugins/lsp.lua`.
2. Only add a `vim.lsp.config("name", {...})` block if the defaults genuinely aren't enough —
   most servers need nothing.
