# Decision history

Every non-obvious choice in this config, in the order it was made, with the context and the
alternatives that were considered. The goal is that nobody — human or AI — has to re-derive *why*
something is the way it is, or accidentally regress a decision that was made deliberately.

New entries go at the bottom. Each one follows the same shape: **Decision**, **Context**,
**Alternatives considered**, and an **Example** where a snippet helps.

---

## Config switching: `NVIM_APPNAME`, not a symlink farm {#config-switching}

**Decision.** Use Neovim's native `NVIM_APPNAME` env var to run nvim-min as a fully separate
install from the existing LazyVim config, plus a small `nvims` picker script for interactive
switching.

**Context.** The ask was to keep the existing LazyVim config untouched while building a second,
faster one, and to be able to switch between them "seamlessly" — the exact pattern several
Neovim YouTube videos demonstrate.

**Alternatives considered.**
- A symlink farm swapping `~/.config/nvim` between two directories — rejected: destructive to
  switch (has to touch the shared path), fragile, and both configs can never be open at once.
- A wrapper shell function reimplementing config selection — `NVIM_APPNAME` already does this
  natively (separate config/data/state/cache dirs per name), so a wrapper would just be
  reinventing a core feature.

**Example.**
```sh
NVIM_APPNAME=nvim-min nvim   # ~/.config/nvim-min, ~/.local/share/nvim-min, ...
NVIM_APPNAME=nvim nvim       # unchanged, your existing LazyVim config
```

---

## Decoupled configuration: a separate CLI, not an in-editor settings UI {#decoupled-config}

**Decision.** All interactive configuration (Gemini API key, theme, feature toggles) lives in
`bin/nvim-min-setup`, a standalone bash script — never in the Lua config, never as an in-editor
prompt or settings buffer.

**Context.** Explicit ask: "minimal nvim with features that we need at runtime and a separate
cli which will allow us to config or customize that setup... i want to decouple this two things
so i have a powerful editor with speed." A settings-UI plugin (or hand-rolled `vim.ui.input`
wizard triggered from inside nvim) would add code that only ever runs once in a while, but still
has to be loaded, parsed, and maintained as part of the editor's startup path.

**Alternatives considered.**
- An in-editor `:NvimMinSetup` command opening a settings buffer — rejected: this is exactly the
  kind of "runs rarely, costs always" surface area the decoupling was meant to eliminate.
- Plain shell exports (`export GEMINI_API_KEY=...` in `.zshrc`) — works, but means secrets and
  theme choice live scattered across shell rc files instead of one place with a `status`/`reset`
  command; kept as a silent fallback (`user_settings.load_secrets()` only sets a var if it isn't
  already set) but not the primary path.

**Example.** The Lua side is deliberately dumb — it just reads two files and falls back to
defaults if they're missing:
```lua
-- lua/config/user_settings.lua
function M.load()
  -- ... reads user/settings.json, vim.tbl_deep_extend("force", DEFAULTS, decoded) on success
end
```

---

## `vtsls`, not `ts_ls` {#vtsls}

**Decision.** Use `vtsls` as the TypeScript/JavaScript language server.

**Context.** `vtsls` wraps the same underlying `tsserver` as `ts_ls` but manages its lifecycle
more efficiently and exposes more configuration (e.g. `maxTsServerMemory`, fine-grained inlay hint
kinds) — meaningful on larger MERN-stack codebases where `ts_ls`'s defaults get noticeably
sluggish.

**Alternatives considered.** `ts_ls` (nvim-lspconfig's more common default) — passed over
specifically because this config's stated priority is LSP speed on real-world project sizes, not
familiarity.

---

## `blink.cmp` pinned to `1.*`, not `main`/v2 {#blink-pin}

**Decision.** Pin `blink.cmp` to `version = "1.*"` in `lua/plugins/completion.lua`.

**Context.** blink.cmp's own README carries an explicit warning: *"V2 is under active development
with many breaking changes. Consider staying on stable by using `branch = 'v1'`."* V2 also
requires a separate companion plugin (`saghen/blink.lib`) that isn't needed at all on v1. Checked
directly against the repo's README rather than assumed from training data (this plugin's API has
changed meaningfully in the recent past).

**Alternatives considered.** Tracking `main`/v2 for the newest features — rejected: this config
values "doesn't break on update" over "has this month's feature," and v2's own maintainers
recommend v1 for exactly that reason.

---

## `nvim-treesitter` on `master`, not `main` {#treesitter-branch}

**Decision.** Pin `nvim-treesitter` to `branch = "master"`.

**Context.** The `main` branch is a full incompatible rewrite (the repo's own README: *"Treat
this as a different plugin you need to set up from scratch"*) that requires a system
`tree-sitter-cli` **0.26+**, installed via a package manager — not npm. This machine's `apt`
candidate for `tree-sitter-cli` is `0.20.8`, far too old, and no `cargo` is installed to build a
newer one from source. `master` compiles parsers with a plain C compiler (`cc`, already required
for other reasons) and needs nothing extra.

**Alternatives considered.** `main` branch — would need either installing Rust/cargo just to
build `tree-sitter-cli`, or fetching a prebuilt binary manually; both add a real setup step for a
plugin that's supposed to "just work" on first launch. Revisit this once `tree-sitter-cli` is
easily installable in this environment.

---

## Native statusline & floating terminal, not plugins {#native-statusline-terminal}

**Decision.** Replace `mini.statusline` + `mini.icons` with `lua/config/statusline.lua`
(`vim.o.statusline` + a render function, no icon font), and `toggleterm.nvim` with
`lua/config/terminal.lua` (`nvim_open_win` + `jobstart(cmd, {term=true})`).

**Context.** Explicit ask for a minimalism audit: *"make sure it's a minimum and all extensions
are there cause we need them if we can use native functionality of nvim instead of them then
remove them."* Neither a statusline nor a floating terminal is something Neovim is missing —
`vim.o.statusline` accepts an arbitrary Lua-backed expression, and terminal buffers plus floating
windows are both fully native APIs. Both replacements are ~40–50 lines total.

**Alternatives considered.** Keeping the plugins for convenience — rejected once it was clear the
native replacement wasn't meaningfully more code, and removed two dependencies plus their
lazy-load registration overhead for zero capability loss.

**Example.**
```lua
-- lua/config/statusline.lua — reuses gitsigns' own buffer-local state instead
-- of shelling out to git again
function M.git()
  local head = vim.b.gitsigns_head
  return (head and head ~= "") and (" " .. head) or ""
end
```

---

## `mason-tool-installer.nvim` cut for a direct `mason-registry` call {#mason-tool-installer}

**Decision.** Don't depend on `mason-tool-installer.nvim` for installing formatters
(`prettierd`/`stylua`/`shfmt`); call `mason-registry` directly in `lua/plugins/lsp.lua` instead.

**Context.** The plugin's entire job for this config's needs — "install these packages if
they're not already installed" — is about ten lines against an API (`mason-registry`) already
loaded as part of `mason.nvim`, which is required regardless. Adding a whole plugin dependency for
that is disproportionate.

**Example.**
```lua
local function mason_ensure_installed(names)
  local registry = require("mason-registry")
  registry.refresh(function()
    for _, name in ipairs(names) do
      local ok, pkg = pcall(registry.get_package, name)
      if ok and not pkg:is_installed() then pkg:install() end
    end
  end)
end
```

---

## Semantic tokens off, inlay hints opt-in {#semantic-tokens}

**Decision.** Disable LSP semantic token highlighting on every attached client
(`client.server_capabilities.semanticTokensProvider = nil`), and leave inlay hints off by default
(`<leader>ch` toggles them per-buffer).

**Context.** Explicit ask to take inspiration from Zed's speed and apply the same discipline to
Neovim's LSP client: don't do work that doesn't pay for itself. Treesitter already highlights
syntax; LSP semantic tokens redo that same work per edit for servers like `vtsls`/`eslint`, for
marginal extra fidelity. Inlay hints cost a request per visible range on every scroll or edit —
real on large files, not worth paying by default. Both are the officially documented Neovim
mechanism for opting out (`:h vim.lsp.semantic_tokens`), not a hack.

**What turned out to already be handled by Neovim core** (checked by reading
`$VIMRUNTIME/lua/vim/lsp/_changetracking.lua` and `_watchfiles.lua` rather than assumed): text-change
debounce already defaults to 150ms, and file-watching already excludes `node_modules/*/**` and
`.git/objects` from polling. No config was added for either — doing so would have been redundant,
and a maintenance trap if core's own defaults ever change.

---

## Two AI plugins, not one: codecompanion + minuet-ai {#two-ai-plugins}

**Decision.** Use `codecompanion.nvim` for chat/inline-assistant and a *separate* plugin,
`minuet-ai.nvim`, specifically for Copilot-style ghost-text completions — both backed by Gemini,
both individually toggleable.

**Context.** codecompanion.nvim is built around an explicit chat buffer and an inline-assistant
you invoke — it has no automatic "suggest as I type" mode. Ghost text is a genuinely different
interaction model (ambient, continuous, low-latency) that calls for a different tool built for
exactly that: minuet-ai's `virtualtext` frontend, which the plugin's own docs recommend *over*
its blink.cmp/nvim-cmp menu integration specifically for this use case (better sorting/async
management is what the menu integration buys you; ghost text is the opposite trade — fast and
ambient).

**Model choice.** Chat uses `gemini-2.5-pro` (quality matters more, it's on-demand). Ghost text
uses `gemini-2.0-flash` with thinking disabled (`thinkingBudget = 0`) — minuet-ai's own docs
recommend exactly this, since the 2.5 models' extended thinking adds latency with no benefit for
line completion.

**Alternatives considered.** `avante.nvim` — heavier (Cursor-like UI, more moving parts) for
capability this config doesn't need. A single plugin covering both chat and ghost text — none of
the well-maintained options do both well; splitting the concern was the correct minimal choice,
not a compromise.

---

## Outsourcing image preview instead of a plugin {#outsourcing-image-preview}

**Decision.** No image/SVG preview plugin. `<leader>ox` shells out to `xdg-open`/`open`;
`<leader>oi` renders inline via `kitten icat` in the existing floating-terminal module.

**Context.** Explicit ask: *"outsource as much as we can so we have less load on our nvim... you
can leverage terminal, other cli tools."* `image.nvim` and similar plugins need a rendering
backend (often ueberzug++ or a terminal graphics protocol wrapper), extra system dependencies,
and redraw-on-scroll handling — real weight for something a terminal (`kitten icat`, using
Kitty's graphics protocol) or the OS's own default app already does perfectly well.

**A bug this surfaced.** The floating-terminal module's original design auto-closed its window
the instant the job inside it exited — correct for an interactive shell or LazyGit (you quit it,
the float goes away), wrong for `kitten icat`, which exits the instant it's done rendering. Fixed
by adding a `close_on_exit` option (default `true`, `false` for one-shot preview commands) rather
than writing a second, parallel "run once" function.

**The general pattern going forward:** before adding a plugin to "view" or "preview" something,
check whether the OS or a terminal tool already does it, and whether the existing floating
terminal (`lua/config/terminal.lua`) already handles the plumbing. Only reach for a plugin if
neither covers it — and hold it to the same "does Neovim/an existing tool already do this?" bar
as everything else (see `CLAUDE.md`).
