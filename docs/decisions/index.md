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

---

## One-command setup: `install.sh` {#install-script}

**Decision.** A single `install.sh` at the repo root: detects the OS/package manager, installs
whatever's missing from the requirements list, symlinks the CLI helpers onto `PATH`, wires the
`nv` alias into the shell rc, bootstraps nvim (plugins, LSP servers, treesitter parsers), and
offers to launch `nvim-min-setup` at the end.

**Context.** Explicit ask: clone the repo, run one script, get a fully working setup — "it should
install everything that needs based on the OS and also trigger that setup config at the end if
user selects that he wants to customize the config."

**Two bugs this surfaced** (both fixed, both worth remembering):
- `mason-lspconfig`'s automatic install **intentionally never runs under `--headless`** — its
  source checks `#vim.api.nvim_list_uis() == 0` and skips `ensure_installed` entirely when true.
  Every one of this session's earlier headless verification attempts silently didn't exercise
  this path at all; it works correctly on a real interactive launch regardless.  `install.sh`
  works around this by calling the exact same install functions
  (`require("mason-lspconfig.features.ensure_installed")`,
  `require("nvim-treesitter.install").ensure_installed_sync()`) directly in a headless session, so
  everything is already installed by the time you open nvim for real.
- Both of those functions live inside plugins (`nvim-lspconfig`, `nvim-treesitter`) that are
  lazy-loaded on file-open events (`BufReadPre`/`BufReadPost`) — with no file buffer open during a
  scripted bootstrap, they never load, and calling their commands/functions directly would either
  no-op (empty `ensure_installed` list) or error (`E492: Not an editor command: TSUpdateSync`).
  Fixed by force-loading them first via lazy.nvim's own scripting API:
  `require("lazy").load({ plugins = { "nvim-treesitter", "nvim-lspconfig" } })`.

**Alternatives considered.** A Dockerfile/devcontainer — heavier, and doesn't help someone
installing directly onto their own machine, which is the actual target here.

**Example.**
```lua
-- the exact fix for both lazy-loading traps above
require("lazy").load({ plugins = { "nvim-treesitter", "nvim-lspconfig" } })
require("nvim-treesitter.install").ensure_installed_sync()
require("mason-registry").refresh(function()
  require("mason-lspconfig.features.ensure_installed")()
end)
```

---

## The setup CLI is a real Node CLI, not a bash+jq script {#node-cli}

**Decision.** Rewrite `bin/nvim-min-setup` from bash+`jq` to Node.js using
[`@clack/prompts`](https://github.com/bombshell-dev/clack) + `picocolors` — the same category of
tooling behind `npm create vite@latest`, `create-t3-app`, and similar scaffolding CLIs.

**Context.** Explicit ask: "can we have the CLI like when creating a vite app, a beautiful CLI."
bash's `select` only does numbered-list menus with no arrow-key navigation, no checkboxes, no
masked password input, and no color beyond raw ANSI codes hand-rolled per line — genuinely
inferior UX to what's being asked for. Since Node + npm are already a hard requirement for this
entire config (Mason installs most LSP servers through npm), requiring Node for the setup CLI too
adds no new category of dependency — it's already there. `jq` is no longer required at all now
that JSON is handled with `JSON.parse`/`JSON.stringify` directly.

**Non-negotiable constraint carried over unchanged:** the CLI's dependencies
(`~/.config/nvim-min/package.json`, `node_modules/`) are entirely separate from anything nvim
loads at runtime — nvim never requires, shells out to, or waits on this tool. `install.sh` runs
`npm install` for the CLI's own deps as one bootstrap step, exactly like it bootstraps nvim's
plugins as a separate step; neither blocks or slows down the other.

**File format contract preserved exactly.** `settings.json` and `secrets.env`'s shape (keys,
structure, the `GEMINI_API_KEY=` line format) didn't change — only the tool that reads and writes
them did. `lua/config/user_settings.lua` needed zero changes.

**Alternatives considered.** `enquirer`/`inquirer` — heavier, older API conventions; `prompts` —
lighter but visually plainer, lacks the boxed intro/outro chrome that gives the "vite-like" feel
specifically asked for. `@clack/prompts` was chosen because its aesthetic (bordered steps, colored
status symbols, grouped prompts) is the closest match to what "like creating a vite app" actually
looks like today.

---

## `mason-lspconfig`'s `automatic_enable` isn't scoped to `ensure_installed` {#automatic-enable-scope}

**Decision.** Explicitly exclude `stylua` from `automatic_enable` in `lua/plugins/lsp.lua`
(`automatic_enable = { exclude = { "stylua" } }`).

**Context.** Discovered while verifying LSP attach end-to-end after `install.sh`: opening a real
`.lua` file showed **two** attached clients — `lua_ls`, and unexpectedly `stylua` (running as
`stylua --lsp`, a real formatting-only LSP mode stylua supports). `stylua` is installed via Mason
purely as a *formatter* for conform.nvim (`mason_ensure_installed({"prettierd", "stylua",
"shfmt"})`), never listed in mason-lspconfig's `ensure_installed`. It turns out
`automatic_enable = true` scans **every installed Mason package**, not just the ones in
`ensure_installed` — and nvim-lspconfig happens to ship a `lsp/stylua.lua` server config, so any
Mason-installed `stylua` gets auto-enabled as an LSP client regardless of why it was installed.
Harmless in effect (conform.nvim already formats via stylua directly, so this was purely
redundant), but it's exactly the kind of "work that doesn't pay for itself" the
[Zed-inspired performance discipline](/guide/lsp-and-performance) argues against, and it was
silent — nothing would have surfaced this without opening a real file and inspecting
`vim.lsp.get_clients()` directly, which is why `CLAUDE.md`'s testing guidance insists on that over
just checking `:LspInfo` shows *a* client.

**Alternatives considered.** Not installing `stylua` via Mason (use a system package instead) —
rejected, loses the auto-install-on-first-launch convenience for no real gain; the exclusion is a
one-line fix.

---

## Theme: onedark.nvim, not catppuccin {#onedark}

**Decision.** Replace `catppuccin/nvim` with
[`navarasu/onedark.nvim`](https://github.com/navarasu/onedark.nvim) as the default (and only)
colorscheme, defaulting to the `dark` style with transparency on.

**Context.** Explicit user preference — Atom One Dark over catppuccin. `onedark.nvim` was picked
over the alternatives (`olimorris/onedarkpro.nvim`, `joshdick/onedark.vim`) because it's actively
maintained, has a native `transparent` option (required — the original ask was always for a
transparent background), and its `style` variants (`dark`/`darker`/`cool`/`deep`/`warm`/`warmer`/
`light`) map cleanly onto the same "pick a variant + transparency" flow `nvim-min-setup theme`
already had for catppuccin's flavours.

**What this loses:** catppuccin's `auto_integrations` (detects installed plugins by name and
applies bespoke highlight refinements for blink_cmp/gitsigns/mason/fzf/mini automatically).
onedark.nvim doesn't have an equivalent — it sets a solid set of general-purpose highlight groups
(`@variable`, `DiagnosticError`, etc.) that every plugin already consumes by convention, so
functionality is unaffected; only some plugin-specific visual polish is. Acceptable per this
config's own stance that UI polish matters less than speed/functionality.

**A migration trap worth knowing about:** `settings.json`'s `theme` field previously held a
catppuccin flavour name (`"mocha"`, `"latte"`, ...). Anyone who ran `nvim-min-setup theme` before
this change has that stale value on disk, and onedark.nvim doesn't recognize it as a valid
`style`. Both consumers guard against this explicitly — `lua/plugins/colorscheme.lua` falls back
to `"dark"` if `settings.theme` isn't one of onedark's known styles, and
`bin/nvim-min-setup`'s `cmdTheme()` does the same for the picker's `initialValue` — rather than
silently passing an invalid value through and letting the colorscheme break or error. This is the
same "config must survive being corrupted" principle from `CLAUDE.md` applied to a value that's
*structurally* valid JSON but *semantically* stale after a schema change one field deep.

**Example.**
```lua
-- lua/plugins/colorscheme.lua
local VALID_STYLES = { dark = true, darker = true, cool = true, deep = true, warm = true, warmer = true, light = true }
local style = VALID_STYLES[settings.theme] and settings.theme or "dark"
```

---

## Start screen: a scratch buffer, not alpha.nvim/dashboard.nvim/snacks {#dashboard}

**Decision.** Build the start screen (shown on launching nvim with no file argument) as a plain
scratch buffer in `lua/config/dashboard.lua` — no dashboard plugin.

**Context.** Explicit ask for a personalized dashboard with recent files and quick actions,
"without any plugins." Everything a dashboard plugin provides is either already native or trivial
to build from native APIs: `vim.v.oldfiles` is Neovim's own recently-opened-files list (populated
from shada, zero extra tracking needed), `require("lazy").stats()` gives the plugin-count/load-time
footer for free, and a scratch buffer (`buftype=nofile`) plus buffer-local `vim.keymap.set` calls
is all a "press a key, do a thing" menu needs.

**A real testing trap this surfaced:** every `nvim --headless ... -c "qa!"` test run showed an
empty buffer, looking exactly like the dashboard wasn't opening. Per `:h VimEnter`, that event
fires only *after* all `-c` command-line arguments have been processed — so a `-c "qa!"` in that
same command line quits Neovim before VimEnter ever fires, regardless of what's registered on it.
Confirmed by registering a bare canary autocmd both with and without a trailing `qa!`: it never
prints with `qa!` present, and prints reliably without it (using `timeout` to end the process
instead). This is the same category of "headless testing lies to you" trap as
[`automatic_enable` under `--headless`](#automatic-enable-scope) — verify VimEnter-triggered
behavior by letting Neovim reach steady-state (e.g. `timeout 5 nvim --headless` with no `-c "qa!"`
tacked on), not by looking at buffer state after a command line that quits before VimEnter runs.

**Why the ASCII logo was generated, not hand-typed.** Block-letter ASCII art is trivial to get
subtly misaligned by hand (one column of spaces off, and every line after it drifts). Generated
correctly once with `figlet -f doom YASH`, verified byte-for-byte (`cat -A` to confirm exact
trailing whitespace), then hardcoded as a literal Lua table — no runtime dependency on `figlet`
being installed, but zero risk of a hand-typed alignment bug either.

**Alternatives considered.** `snacks.nvim`'s dashboard module — genuinely nice, but it's one
module of a much larger multi-purpose plugin; pulling in the whole thing for a start screen fails
the same "does this need a plugin" bar as everything else here.

---

## Statusline redesign: theme-derived colors, hidden on the dashboard, no LSP client list {#statusline-v2}

**Decision.** Give the native statusline (`lua/config/statusline.lua`) real color: a per-mode
colored "pill" (bg color from `require("onedark.colors")`, so it always matches whichever onedark
style is active) plus colored git-branch/diagnostic text. Drop the LSP client-name list entirely.
Blank the statusline completely while on the dashboard. Replace the dashboard's
`require("lazy").stats()` footer ("N plugins loaded in Xms") with a rotating slogan.

**Context.** Explicit feedback after seeing the dashboard rendered: the bottom line showed
`[Scratch][-] ... [dashboard]  20:1  All` — visibly wrong, and the ask was for something "minimal
yet very useful and effective" with git branch, plus for it to disappear entirely on the
dashboard. Also asked to replace the plugin-count footer with a Sanskrit slogan
("वीरभोग्या वसुन्धरा" / *Vīrabhogyā Vasundharā* — "the earth is enjoyed by the brave"), given in
full rather than abbreviated. `SLOGANS` in `lua/config/dashboard.lua` is a list (currently one
entry) specifically so more can be added later without restructuring anything.

**Root cause of the `[Scratch]` bug:** `%f` genuinely renders as `[Scratch]` for an unnamed
`buftype=nofile` buffer (confirmed with `vim.api.nvim_eval_statusline()`, which evaluates a
statusline expression to its final text — the right tool for checking what a statusline will
actually show, rather than reasoning about it from the format string alone). `%m` showed `[-]`
because the dashboard buffer is `modifiable = false` (that flag means "not modifiable", not
"unmodified"). Neither was a bug in the render function; the function just had no reason to know
it was looking at a special buffer, so it rendered the generic file-info format for it too.

**A genuinely non-obvious Neovim behavior this surfaced:** with `laststatus = 3` (one global
statusline for the whole tabpage, set in `lua/config/options.lua`), there is no such thing as a
true per-window statusline override anymore — confirmed by setting `vim.wo.statusline` in one
window and observing `vim.o.statusline` (the *global* value) change too. So "hide the statusline
only on the dashboard window" cannot be done by setting a window-local option; it has to be done
inside `render()` itself, which already runs fresh on every redraw and can check
`vim.bo.filetype == "dashboard"` directly. This is the only correct way to make one buffer's
statusline look different from another's under `laststatus = 3`.

**Alternatives considered.** `laststatus = 2` (a statusline per window) would make window-local
overrides work normally, but it was chosen deliberately as `3` from the start for the cleaner
single-bar look with splits — not worth reversing for this.

---

## Statusline pills use Powerline glyphs, verified before use {#statusline-pills}

**Decision.** Render the mode and git-branch segments as rounded "pill" capsules using the
Powerline Extra Symbols `ple-left_half_circle_thick` (`U+E0B6`) and `ple-right_half_circle_thick`
(`U+E0B4`), each pill's outer edge colored to match its fill and `bg = "NONE"` so it floats on the
theme's transparent background — directly modeled on the tmux status bar screenshot that prompted
this.

**Context.** These are Nerd Font Private Use Area glyphs — the exact category of icon-font
dependency this config deliberately avoided when `mini.icons` was cut (see the native
statusline/dashboard decision above). The difference here: the *user's own terminal* was already
proven to render these glyphs correctly, because the reference screenshot's tmux bar uses the same
glyph family. Depending on a font the environment demonstrably already has is a different call
than adding a new hard requirement nothing previously needed.

**Verified, not guessed, before using them.** Powerline separator glyphs are easy to get backwards
(there are visually similar codepoints for hard/pointed vs. round, and left vs. right variants of
each). Checked the canonical Nerd Fonts `glyphnames.json` for the exact name/codepoint mapping
(`ple-left_half_circle_thick` = `U+E0B6`, `ple-right_half_circle_thick` = `U+E0B4`) rather than
recalling it from memory, then confirmed the rendered statusline string contained the exact
expected UTF-8 byte sequences (`0xEE 0x82 0xB6` and `0xEE 0x82 0xB4`) via
`vim.api.nvim_eval_statusline()` before considering it done.

---

## Oil.nvim must not be lazy-loaded {#oil-eager}

**Decision.** Set `lazy = false` on oil.nvim's plugin spec, removing the `cmd`/`keys`-based lazy
triggers it had before.

**Context.** Reported bug: `<leader>e` and `:Oil` intermittently didn't work. Root cause was in
oil.nvim's own README, not a bug in this config's keymaps: *"Lazy loading is not recommended
because it is very tricky to make it work correctly in all situations"* — `default_file_explorer
= true` needs oil's netrw-override autocmds registered before you ever open a directory, which a
`cmd`/`keys`-triggered lazy load can't guarantee happens in time. Oil is small; eager-loading it
costs nothing meaningful at startup. This is a case where a plugin's *own* documentation
explicitly overrides this config's general "lazy-load everything that can be" default —
worth checking a plugin's install instructions for an explicit anti-recommendation like this
before assuming lazy-loading is always the right call.

---

## Mason stops retrying basedpyright/ruff when `python3-venv` is missing {#mason-venv-skip}

**Decision.** Check once, at LSP setup time, whether `python3 -c "import venv"` succeeds; only add
`basedpyright`/`ruff` to `ensure_installed` if it does. If not, skip both and show one clear
`vim.notify` explaining exactly what to install, instead of letting Mason retry-and-fail them on
every single launch.

**Context.** This dependency was already documented (see the Requirements sections in
`README.md`/`docs/guide/getting-started.md`) and `install.sh` already checks for it — but a user
who launches nvim without having run `install.sh` (or on a machine where the `apt-get` step
silently failed) would see a scary, uninformative red error — `[mason-lspconfig.nvim] failed to
install ruff. Installation logs are available in :Mason and :MasonLog` — on *every single launch*,
since mason-lspconfig has no memory of "I already tried this and it doesn't work here." That's
wasted network/CPU on every startup plus an alarming message that gives no indication of what's
actually wrong or how to fix it. Checking once and explaining the real cause is strictly better
than either silently swallowing the failure or letting it repeat forever.

---

## Blink.cmp tuned for latency, LSP debounce lowered {#completion-speed}

**Decision.** Set `completion.trigger.show_on_insert = true` in blink.cmp (show suggestions the
moment you enter insert mode, not just after the first keystroke), and lower
`flags.debounce_text_changes` from Neovim's own 150ms default to 15ms across every LSP client.

**Context.** Explicit priority: "I rely heavily on the auto-complete suggestions... I want them to
be precise and as fast as possible." blink.cmp's own defaults are already close to optimal —
`menu.auto_show_delay_ms = 0`, the Rust fuzzy matcher (0.5–4ms/keystroke), and `frecency`/
`use_proximity` (both on by default) already handle "precise" by ranking your actual usage
patterns and nearby-word matches higher. The one real lever left was `debounce_text_changes`,
which controls how long Neovim waits after a keystroke before telling the LSP server about it at
all — 150ms is a sensible default for general responsiveness, but it directly adds to how long a
completion request takes to even start when it's the thing you interact with the most. This is a
deliberate, explained override of the earlier ["semantic tokens
off"](#semantic-tokens) decision's stance that Neovim's own default was fine as-is — that
decision optimized for "don't do unnecessary work"; this one optimizes for "the primary workflow's
answers should be as fast as possible," a different priority the user stated explicitly, not a
contradiction that was missed.

---

## Harpoon-style file marks, no plugin {#harpoon}

**Decision.** `lua/config/harpoon.lua`: a numbered, per-project-persisted list of marked file
paths, stored as JSON at `stdpath("state") .. "/harpoon/<sha256 of cwd>.json"` — `<leader>ma` to
mark, `<leader>1`–`<leader>9` to jump straight to a slot, `<leader>ml` for a fuzzy-searchable list
(via `fzf-lua.fzf_exec` — "searchable" for free, no picker UI to hand-build).

**Context.** Explicit ask, harpoon.nvim named directly as the reference: numbered marks with
instant jump, distinct from just cycling recently-used buffers (`vim.v.oldfiles`/`<leader>fr`
already cover that). The persistence design intentionally matches real harpoon.nvim's own
behavior — marks survive restarts, scoped per-project via a hash of `cwd` — rather than a
session-only imitation that resets every launch, since "pin these exact files and always jump to
them" is the actual value harpoon provides, not just numbered recency.

**Alternatives considered.** Session-only (in-memory, no persistence) — simpler, but loses the
main reason to reach for numbered marks over the buffer list in the first place: they're supposed
to stay put.
