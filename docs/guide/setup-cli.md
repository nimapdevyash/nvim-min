# The setup CLI

`nvim-min-setup` is the *only* place nvim-min is configured interactively. The editor itself reads
two files at startup and otherwise never prompts you for anything — see
[Decision history → Decoupled configuration](/decisions/#decoupled-config)
for why.

It's a small Node CLI built with [`@clack/prompts`](https://github.com/bombshell-dev/clack) —
arrow-key select menus, masked password input, checkboxes for feature toggles — the same category
of polish as `npm create vite@latest`, not a plain `read`/`select` bash script. See
[Decision history → The setup CLI is a real Node CLI](/decisions/#node-cli) for why. `install.sh`
installs its dependencies (`@clack/prompts`, `picocolors` — nothing nvim itself needs) as part of
first-time setup; run it again any time with `cd ~/.config/nvim-min && npm install`.

```
nvim-min-setup            interactive menu
nvim-min-setup ai         set your Gemini API key
nvim-min-setup theme      pick a onedark style + transparency
nvim-min-setup features   turn AI ghost-text / AI chat on or off
nvim-min-setup status     show current settings (never prints the key back)
nvim-min-setup reset      restore theme/feature settings to defaults
```

## AI (Gemini API key)

```sh
nvim-min-setup ai
```

Prompts for your key (input hidden, never echoed), and writes it to
`~/.config/nvim-min/user/secrets.env` as `GEMINI_API_KEY=...`, `chmod 600`. Get a key at
[aistudio.google.com/apikey](https://aistudio.google.com/apikey).

This file is loaded into the environment by `lua/config/user_settings.lua`, called first thing in
`init.lua` — before any plugin spec is even evaluated — so codecompanion and minuet-ai see
`GEMINI_API_KEY` exactly as if you'd exported it yourself.

## Theme

```sh
nvim-min-setup theme
```

Picks a [onedark.nvim](https://github.com/navarasu/onedark.nvim) style (`dark` / `darker` /
`cool` / `deep` / `warm` / `warmer` / `light`) and whether the background is transparent. Written
to `~/.config/nvim-min/user/settings.json`, read by `lua/plugins/colorscheme.lua` on the next
launch.

## Features

```sh
nvim-min-setup features
```

Toggles `ghost_text` (minuet-ai.nvim) and `ai_chat` (codecompanion.nvim) independently. **This is
not a runtime no-op** — disabling a feature sets `enabled = false` on that plugin's lazy.nvim
spec, so it doesn't load at all on the next launch. That's a real startup-time saving, not a
hidden flag checked at runtime.

There's a second, session-only lever that's *not* part of the CLI: `<leader>at` inside nvim
toggles ghost text for the current session without touching `settings.json`. Use the CLI for "I
don't want this loaded, period"; use `<leader>at` for "not right now."

## Status and reset

```sh
nvim-min-setup status   # current settings + whether a key is set (never the key itself)
nvim-min-setup reset     # restore settings.json to defaults (the API key is untouched)
```

**Nothing here can permanently break the editor.** If `settings.json` goes missing or gets
corrupted by hand-editing, `lua/config/user_settings.lua` falls back to the exact same defaults
the CLI ships with — nvim never fails to start over a bad settings file.
`nvim-min-setup reset` just makes that explicit instead of relying on the implicit fallback.

## Where things live

| File | Contents | Tracked in git? |
|---|---|---|
| `~/.config/nvim-min/user/settings.json` | theme, transparency, feature toggles | No — gitignored |
| `~/.config/nvim-min/user/secrets.env` | `GEMINI_API_KEY=...` | No — gitignored, `chmod 600` |
| `~/.config/nvim-min/bin/nvim-min-setup` | the CLI itself | **Yes** |
| `~/.config/nvim-min/package.json` | the CLI's own deps (`@clack/prompts`, `picocolors`) | **Yes** (`node_modules/` gitignored) |
