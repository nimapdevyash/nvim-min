# Switching configs

Neovim's native [`NVIM_APPNAME`](https://neovim.io/doc/user/starting.html#%24NVIM_APPNAME)
environment variable picks a completely isolated config: its own `~/.config/<name>`,
`~/.local/share/<name>`, `~/.local/state/<name>`, and cache directory. Nothing about nvim-min
touches an existing LazyVim (or any other) config at `~/.config/nvim` — they're fully independent
installs that happen to share the same `nvim` binary.

## Three ways to switch

### 1. `nvims` — an `nvm`-style picker

`~/.local/bin/nvims` fuzzy-picks between every `~/.config/nvim*` directory on the machine, with a
preview pane showing each config's `README.md`:

```sh
nvims              # interactive picker (fzf)
nvims nvim-min     # jump straight to this config
nvims nvim         # jump straight to your other config
```

Adding a third config later — a stripped-down `nvim-writing`, say — is just another directory
under `~/.config/nvim*`. `nvims` picks it up automatically; nothing here needs to change.

### 2. Shell aliases

```sh
# nvim (unchanged) -> ~/.config/nvim
# nv               -> ~/.config/nvim-min
alias nv="NVIM_APPNAME=nvim-min nvim"
```

### 3. Set `NVIM_APPNAME` directly

For scripting or CI:

```sh
NVIM_APPNAME=nvim-min nvim --headless -c "quit"
```

## Why this and not something else

See [Decision history → Config switching](/decisions/#config-switching)
for the reasoning (a symlink farm or a wrapper script were the alternatives considered).
