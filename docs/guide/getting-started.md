# Getting started

nvim-min is a from-scratch Neovim config that sits *alongside* your existing config — it doesn't
replace it, doesn't touch it, and can be removed without leaving a trace anywhere else.

## Requirements

- Neovim **0.12+**
- `git`, `curl`, `tar`, a C compiler (`cc`) — treesitter parsers compile on first use
- [`fzf`](https://github.com/junegunn/fzf), [`ripgrep`](https://github.com/BurntSushi/ripgrep) — fuzzy finding / grep
- [`lazygit`](https://github.com/jesseduffield/lazygit) — `<leader>gg`
- `node` + `npm` — most LSP servers/formatters install through Mason via npm
- `jq` — used by the [setup CLI](/guide/setup-cli), not by nvim itself
- A [Gemini API key](https://aistudio.google.com/apikey) for the AI features (optional, see [AI features](/guide/ai-features))

## Install

If you're reading this from the repo you already have it — clone it to `~/.config/nvim-min` if
you don't:

```sh
git clone https://github.com/nimapdevyash/nvim-min ~/.config/nvim-min
```

Symlink the setup CLI onto your `PATH` (or run it directly from `bin/`):

```sh
ln -s ~/.config/nvim-min/bin/nvim-min-setup ~/.local/bin/nvim-min-setup
```

## Configure

nvim-min never asks you anything at runtime. Configure it *before* opening it:

```sh
nvim-min-setup ai        # paste your Gemini API key
nvim-min-setup theme     # pick a catppuccin flavour + transparency
```

Full CLI reference: [The setup CLI](/guide/setup-cli).

## First launch

```sh
NVIM_APPNAME=nvim-min nvim
```

...or use the [`nvims` picker or `nv` alias](/guide/switching-configs) if you've set those up.

First launch installs plugins, LSP servers, and treesitter parsers — this genuinely takes a
minute or two (Mason installs ~15 language servers via npm). Once it settles, run
`:checkhealth vim.lsp` to confirm servers came up, and open a real `.ts`/`.py`/`.tf` file to check
`gd`, `K`, and `<leader>ca` actually work — an empty buffer won't exercise any of it.

## Next

- [Switching configs](/guide/switching-configs) — how this coexists with LazyVim or anything else
- [Keybindings](/guide/keybindings) — the full reference, searchable in-editor with `<leader>?`
- [AI features](/guide/ai-features) — Gemini chat and ghost-text completion
- [Decision history](/decisions/) — why things are built the way they are
