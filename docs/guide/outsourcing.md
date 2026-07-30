# Outsourcing to CLI tools instead of plugins

Some things are better delegated to a real terminal tool or the OS than reimplemented as an nvim
plugin. Image preview is the clearest example: `image.nvim` and similar plugins need a rendering
backend, extra dependencies, and repaint-on-scroll logic just to show a PNG. nvim-min shells out
instead — see [Decision history](/decisions/#outsourcing-image-preview) for
the full reasoning.

## Preview images, SVGs, PDFs

`lua/config/external.lua` figures out "what file are we talking about" (a snacks explorer entry
under the cursor, else a path under the cursor via `<cfile>`, else the current buffer) and hands
it to:

| Key | Action |
|---|---|
| `<leader>ox` | Open in the OS default app (`xdg-open` / `open`) |
| `<leader>oi` | Preview inline in a floating terminal via [kitty's `icat`](https://sw.kovidgoyal.net/kitty/kittens/icat/), falling back to `<leader>ox` if `kitten` isn't installed |

Both are fire-and-forget — `<leader>ox` detaches the job entirely so it can't block or crash
nvim; `<leader>oi` reuses the same floating-terminal module as LazyGit (`lua/config/terminal.lua`)
with one difference: the window doesn't auto-close when the job exits, since `kitten icat` exits
the instant it finishes rendering and closing immediately would mean you never see the image.

## The general pattern

Before reaching for a plugin to "view" or "preview" something, check:

1. Does the OS already have a way to open it? → `xdg-open`/`open`, fire-and-forget via
   `vim.fn.jobstart({...}, { detach = true })`.
2. Is there a good terminal-native tool for it? → the floating terminal in
   `lua/config/terminal.lua` (`M.toggle(key, cmd, opts)`) already handles the "open a scratch
   float, run a job in it, manage its lifecycle" plumbing. Reuse it.
3. Only if neither covers it well, consider a plugin — and hold it to the same bar as everything
   else in this config (see `CLAUDE.md` principle #1).
