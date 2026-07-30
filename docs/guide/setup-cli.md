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
nvim-min-setup ai         set an API key, pick which provider chat / ghost text each use
nvim-min-setup theme      pick a onedark style + transparency
nvim-min-setup features   turn AI ghost-text / AI chat on or off
nvim-min-setup status     show current settings (never prints a key back)
nvim-min-setup doctor     check system requirements (rg, fd, lazygit, tree-sitter-cli, ...)
nvim-min-setup reset      restore settings to defaults (optionally wipe API keys too)
```

## AI (provider + API key)

```sh
nvim-min-setup ai
```

Two independent things happen here, on purpose:

1. **Set/replace/clear a key** for Gemini, OpenAI, or Anthropic. You can hold keys for as many
   providers as you like at once — this just writes to `~/.config/nvim-min/user/secrets.env` as
   `GEMINI_API_KEY=...` / `OPENAI_API_KEY=...` / `ANTHROPIC_API_KEY=...`, `chmod 600`. Before
   saving, the CLI makes a real (short-timeout) request to that provider's own API to confirm the
   key actually works — if the network's unreachable it says so and saves anyway rather than
   blocking you.
2. **Choose which provider chat (`codecompanion.nvim`) and ghost text (`minuet-ai.nvim`) each
   use** — independently. Nothing stops you running Claude for chat and Gemini for ghost text;
   they're already two separate plugins for two different jobs (quality vs. speed — see
   [Decision history → Two AI plugins, not one](/decisions/#two-ai-plugins)).

Get a key: [Gemini](https://aistudio.google.com/apikey) ·
[OpenAI](https://platform.openai.com/api-keys) ·
[Anthropic](https://console.anthropic.com/settings/keys).

`secrets.env` is loaded into the environment by `lua/config/user_settings.lua`, called first thing
in `init.lua` — before any plugin spec is even evaluated — so codecompanion and minuet-ai see
whichever `*_API_KEY` they need exactly as if you'd exported it yourself.

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

## Doctor

```sh
nvim-min-setup doctor
```

Checks the same requirements `install.sh` installs — git, curl, ripgrep, fd, lazygit, Neovim
0.12+, tree-sitter-cli 0.26+, a working python3 venv+pip, plus whether `settings.json` parses and
`secrets.env` has the right permissions — and reports each with a clear ✓/✗ instead of you
discovering a missing binary secondhand, from a confusing error somewhere else. Doesn't fix
anything itself; re-run `./install.sh` for that.

## Status and reset

```sh
nvim-min-setup status   # current settings + which keys are set (never a key itself)
nvim-min-setup reset     # restore settings to defaults — optionally wipes API keys too
```

`reset` asks explicitly whether you want theme/feature settings reset (API keys kept) or
everything including every stored key (a second confirmation, since that's the destructive path).

**Nothing here can permanently break the editor.** If `settings.json` goes missing or gets
corrupted by hand-editing, `lua/config/user_settings.lua` falls back to the exact same defaults
the CLI ships with — nvim never fails to start over a bad settings file.
`nvim-min-setup reset` just makes that explicit instead of relying on the implicit fallback.

## Where things live

| File | Contents | Tracked in git? |
|---|---|---|
| `~/.config/nvim-min/user/settings.json` | theme, transparency, per-feature AI provider, feature toggles | No — gitignored |
| `~/.config/nvim-min/user/secrets.env` | `GEMINI_API_KEY=...` / `OPENAI_API_KEY=...` / `ANTHROPIC_API_KEY=...` | No — gitignored, `chmod 600` |
| `~/.config/nvim-min/bin/nvim-min-setup` | the CLI itself | **Yes** |
| `~/.config/nvim-min/package.json` | the CLI's own deps (`@clack/prompts`, `picocolors`) | **Yes** (`node_modules/` gitignored) |
