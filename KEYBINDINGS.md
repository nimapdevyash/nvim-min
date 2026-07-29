# Keybindings

Single source of truth: [`lua/config/keymaps.lua`](lua/config/keymaps.lua). This file is a
readable mirror of it — if they ever drift, the Lua file wins.

There's no which-key popup by design (it adds a plugin, an on-keypress popup, and load-time
overhead you don't need once these are muscle memory). Instead:

- `<leader>?` — fuzzy-search **every** live keymap (via fzf-lua, always accurate, shows source)
- `<leader>fK` — grep the raw `keymaps.lua` source
- `:h {motion}` — Neovim's own help, for anything built-in (`y`, `d`, `ci"`, etc.)

Leader is `<space>`.

## General

| Key | Action |
|---|---|
| `<Esc>` | Clear search highlight |
| `jk` | Exit insert mode |
| `<leader>w` | Save file |
| `<leader>W` | Save all files |
| `<leader>q` | Quit window |
| `<leader>Q` | Quit all (discard changes) |
| `x` | Delete char without yanking |
| `<leader>y` / `<leader>Y` | Yank to system clipboard (selection / line) |
| `<leader>p` | Paste without overwriting the register |
| `J` / `K` (visual) | Move selection down / up |
| `<` / `>` (visual) | Indent, keep selection |

## Windows / splits

| Key | Action |
|---|---|
| `<C-h/j/k/l>` | Move focus between windows |
| `<leader>sv` / `<leader>sh` | Split vertically / horizontally |
| `<leader>se` | Equalize window sizes |
| `<leader>sx` | Close split |
| `<C-Up/Down/Left/Right>` | Resize window |

## Buffers

| Key | Action |
|---|---|
| `<S-l>` / `<S-h>` | Next / previous buffer |
| `<leader>bd` | Delete buffer |
| `<leader>bo` | Delete all other buffers |

## Find (fzf-lua)

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep project |
| `<leader>fw` | Grep word under cursor |
| `<leader>fb` | Find buffers |
| `<leader>fr` | Recent files |
| `<leader>fh` | Help tags |
| `<leader>fd` | Workspace diagnostics |
| `<leader>fc` | Git commits |
| `<leader>fs` | Git status (files) |
| `<leader>fR` | Resume last picker |

## Files (oil.nvim)

| Key | Action |
|---|---|
| `-` | Open parent directory (edit filesystem like a buffer) |
| `<leader>e` | Open file manager |

## Diagnostics

| Key | Action |
|---|---|
| `]d` / `[d` | Next / previous diagnostic |
| `<leader>cd` | Line diagnostics (float) |
| `<leader>cq` | Diagnostics to location list |

## LSP (buffer-local, set on attach)

| Key | Action |
|---|---|
| `gd` | Goto definition |
| `gD` | Goto declaration |
| `gr` | Goto references |
| `gI` | Goto implementation |
| `gy` | Goto type definition |
| `K` | Hover docs |
| `<C-k>` (insert) | Signature help |
| `<leader>ca` | Code action |
| `<leader>rn` | Rename symbol |
| `<leader>cs` | Document symbols |
| `<leader>cS` | Workspace symbols |
| `<leader>cf` | Format buffer |
| `<leader>ci` | `:checkhealth vim.lsp` |
| `<leader>cm` | Mason installer UI |

## Git (gitsigns)

| Key | Action |
|---|---|
| `]c` / `[c` | Next / previous hunk |
| `<leader>gs` | Stage hunk (normal or visual selection) |
| `<leader>gr` | Reset hunk |
| `<leader>gp` | Preview hunk |
| `<leader>gb` | Blame line (full) |
| `<leader>gB` | Toggle inline blame |
| `<leader>gd` | Diff against index |
| `<leader>gu` | Undo all hunks in buffer |
| `<leader>gg` | Open LazyGit |

## Terminal

| Key | Action |
|---|---|
| `<C-\>` | Toggle floating terminal |
| `<Esc>` (terminal mode) | Exit terminal mode |

## AI / Gemini (codecompanion)

| Key | Action |
|---|---|
| `<leader>aa` | Toggle chat |
| `<leader>ac` | Actions palette |
| `<leader>aA` (visual) | Add selection to chat |
| `<leader>ai` | Inline prompt (type a task, `<cr>`) |
