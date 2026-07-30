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
   ripgrep, fd, lazygit, node+npm, Python's `venv` module) — preferring whichever package manager
   actually has a current-enough version per tool (e.g. Arch's pacman for `tree-sitter-cli`/
   `lazygit`/Neovim itself, verified directly against each distro's real package repo rather than
   assumed), falling back to Homebrew/Linuxbrew where a distro's own package is too old.
2. Installs `nvim-min-setup`'s own dependencies and symlinks it (and `nvims`) onto your `PATH`.
3. Wires the `nv` alias and PATH entry into **every shell rc file actually relevant on your
   machine** — bash's `.bashrc`+`.bash_profile`, zsh's `.zshrc`, fish's `config.fish`, plus
   `.profile` as a fallback — not just one guessed from `$SHELL`. Idempotent, safe to re-run.
4. Bootstraps nvim itself: plugins, LSP servers, treesitter parsers. Genuinely takes a few minutes
   the first time (Mason installs ~15 language servers via npm) — that's normal.
5. Offers to launch the interactive setup CLI right then, so you can set an AI provider/key and
   pick a theme before you ever open nvim.

Every run writes a full transcript to `~/.cache/nvim-min/install.log`; if a step fails, the script
tells you exactly which step, which command, and which line failed — see
[Troubleshooting](#troubleshooting) below.

See [Decision history → One-command setup](/decisions/#install-script) for why it's built this
way, including two real headless-Neovim gotchas it works around, and
[→ Every shell, not one guess](/decisions/#shell-agnostic-install) for the PATH/alias wiring.

## Configure any time

Didn't set your API key or theme during `install.sh`? Run the CLI directly:

```sh
nvim-min-setup ai        # pick a provider (Gemini/OpenAI/Anthropic), set its API key
nvim-min-setup theme     # pick a onedark style + transparency
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
- [`ripgrep`](https://github.com/BurntSushi/ripgrep), [`fd`](https://github.com/sharkdp/fd) (optional but recommended) — fuzzy finding / grep
- [`lazygit`](https://github.com/jesseduffield/lazygit) — `<leader>gg`
- `node` + `npm` — most LSP servers/formatters install through Mason via npm; also runs the setup CLI
- Python's `venv` module (`python3-venv` on Debian/Ubuntu) — needed for `basedpyright`/`ruff` to install
- An API key for at least one AI provider — Gemini, OpenAI, or Anthropic (optional, see
  [AI features](/guide/ai-features))

## Troubleshooting

```sh
nvim-min-setup doctor
```

Checks the same requirements `install.sh` installs, live, against your actual system — a missing
binary, a stale `tree-sitter-cli`, or wrong `secrets.env` permissions show up as a clear ✓/✗
instead of a confusing failure somewhere downstream. Doesn't fix anything itself; re-run
`./install.sh` for that.

If `install.sh` itself fails partway through, it already tells you exactly which step, which
command, and which line — plus the full transcript is always at `~/.cache/nvim-min/install.log`
(overwritten fresh each run). That log is also the fastest way to compare a working run on one
machine/distro against a failing one on another.

## Next

- [Switching configs](/guide/switching-configs) — how this coexists with LazyVim or anything else
- [Keybindings](/guide/keybindings) — the full reference, searchable in-editor with `<leader>?`
- [AI features](/guide/ai-features) — chat and ghost-text completion, Gemini/OpenAI/Anthropic
- [Decision history](/decisions/) — why things are built the way they are
