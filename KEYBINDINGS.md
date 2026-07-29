# Keybindings

Single source of truth: [`lua/config/keymaps.lua`](lua/config/keymaps.lua). This file is a
readable mirror of it — if they ever drift, the Lua file wins.

There's no which-key popup by design (it adds a plugin, an on-keypress popup, and load-time
overhead you don't need once these are muscle memory). Instead:

| Key | Action |
|---|---|
| `<leader>?` | Fuzzy-search **every** live keymap (via fzf-lua, always accurate, shows source) |
| `<leader>fK` | Grep the raw `keymaps.lua` / `lua/config` source |

Plus `:h {motion}` — Neovim's own help, for anything built-in (`y`, `d`, `ci"`, etc.)

Leader is `<space>`.

## General

| Key | Action |
|---|---|
| `<leader>h` | Open the start screen (dashboard) |
| `<Esc>` | Clear search highlight |
| `jk` (insert) | Exit insert mode |
| `<leader>w` | Save file |
| `<leader>W` | Save all files |
| `<leader>q` | Quit window |
| `<leader>Q` | Quit all (discard changes) |
| `x` | Delete char without yanking |
| `<leader>y` / `<leader>Y` | Yank to system clipboard (selection / line) |
| `<leader>p` | Paste without overwriting the register |
| `J` | Join line, keep cursor position |
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
| `<leader>ch` | Toggle inlay hints (off by default — real cost on big files) |

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

## AI chat (codecompanion, Gemini)

| Key | Action |
|---|---|
| `<leader>aa` | Toggle chat |
| `<leader>ac` | Actions palette |
| `<leader>aA` (visual) | Add selection to chat |
| `<leader>ai` | Inline prompt (type a task, `<cr>`) |
| `<leader>ax` | Close chat input (stop insert, leave chat buffer open) |

## AI ghost text (minuet-ai, Gemini)

Inline Copilot-style suggestions. Auto-triggers only in the languages this config targets — see
README.md → "AI ghost text" for the exact list.

| Key | Action |
|---|---|
| `<Tab>` | Accept whole suggestion (falls through to blink.cmp's normal Tab if no ghost text is showing) |
| `<A-a>` | Accept one line |
| `<A-z>` | Accept N lines (prompts for count) |
| `<A-]>` / `<A-[>` | Next / previous suggestion |
| `<A-e>` | Dismiss |
| `<leader>at` | Toggle ghost text for this session only (persistent on/off is `nvim-min-setup features`) |

Turning AI features fully off (not loading the plugin at all) is done outside nvim entirely:
`nvim-min-setup features`.

## Open externally (images, SVGs, PDFs)

No image-preview plugin — that's real rendering-backend weight for something a terminal or the
OS already does. These just shell out. Target is: an oil.nvim entry under the cursor, else a path
under the cursor (`<cfile>`), else the current buffer.

| Key | Action |
|---|---|
| `<leader>ox` | Open in the OS default app (`xdg-open`/`open`) |
| `<leader>oi` | Preview inline in a floating terminal via `kitten icat`, falls back to `<leader>ox` if `kitten` isn't installed |

## Start screen (dashboard)

Shows automatically on launching nvim with no file argument; reopen any time with `<leader>h` or
`:Dashboard`. No plugin — see `lua/config/dashboard.lua`. Keys are buffer-local, only active on
the dashboard itself.

| Key | Action |
|---|---|
| `1`–`5` | Open that recent file (from `vim.v.oldfiles`, whichever still exist on disk) |
| `f` | Find files |
| `g` | Live grep |
| `r` | Recent files (full fzf-lua picker) |
| `e` | File manager (oil.nvim) |
| `a` | AI chat |
| `n` | New file |
| `q` | Quit |
