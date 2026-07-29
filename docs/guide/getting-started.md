# Getting started

nvim-min is a from-scratch Neovim config that sits *alongside* your existing config — it doesn't
replace it, doesn't touch it, and can be removed without leaving a trace anywhere else.

## One command

```sh
git clone https://github.com/nimapdevyash/nvim-min ~/.config/nvim-min
cd ~/.config/nvim-min && ./install.sh
```

That's the whole setup. `install.sh`:

1. Detects your OS/package manager and installs whatever's missing (git, curl, tar, a C compiler,
   fzf, ripgrep, lazygit, node+npm, Python's `venv` module).
2. Installs `nvim-min-setup`'s own dependencies and symlinks it (and `nvims`) onto your `PATH`.
3. Wires the `nv` alias into your shell rc — idempotent, safe to re-run.
4. Bootstraps nvim itself: plugins, LSP servers, treesitter parsers. Genuinely takes a few minutes
   the first time (Mason installs ~15 language servers via npm) — that's normal.
5. Offers to launch the interactive setup CLI right then, so you can paste your Gemini key and
   pick a theme before you ever open nvim.

See [Decision history → One-command setup](/decisions/#install-script) for why it's built this
way, including two real headless-Neovim gotchas it works around.

## Configure any time

Didn't set your API key or theme during `install.sh`? Run the CLI directly:

```sh
nvim-min-setup ai        # paste your Gemini API key
nvim-min-setup theme     # pick a catppuccin flavour + transparency
```

Full CLI reference: [The setup CLI](/guide/setup-cli).

## Launch

```sh
nv
```

...or `NVIM_APPNAME=nvim-min nvim` directly, or the [`nvims` picker](/guide/switching-configs).
Once it settles, run `:checkhealth vim.lsp` to confirm servers came up, and open a real
`.ts`/`.py`/`.tf` file to check `gd`, `K`, and `<leader>ca` actually work — an empty buffer won't
exercise any of it.

## Requirements

Handled for you by `install.sh` — listed here for reference:

- Neovim **0.12+**
- `git`, `curl`, `tar`, a C compiler (`cc`) — treesitter parsers compile on first use
- [`fzf`](https://github.com/junegunn/fzf), [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fuzzy finding / grep
- [`lazygit`](https://github.com/jesseduffield/lazygit) — `<leader>gg`
- `node` + `npm` — most LSP servers/formatters install through Mason via npm; also runs the setup CLI
- Python's `venv` module (`python3-venv` on Debian/Ubuntu) — needed for `basedpyright`/`ruff` to install
- A [Gemini API key](https://aistudio.google.com/apikey) for the AI features (optional, see [AI features](/guide/ai-features))

## Next

- [Switching configs](/guide/switching-configs) — how this coexists with LazyVim or anything else
- [Keybindings](/guide/keybindings) — the full reference, searchable in-editor with `<leader>?`
- [AI features](/guide/ai-features) — Gemini chat and ghost-text completion
- [Decision history](/decisions/) — why things are built the way they are
