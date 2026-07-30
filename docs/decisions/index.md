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

---

## nvim-treesitter: switched from `master` to `main` after a real crash {#treesitter-main}

**Decision.** Reverse the earlier [`master`-branch pin](#treesitter-branch): move to `main`
(the actively-maintained rewrite), and have `install.sh` install a genuine `tree-sitter-cli`
0.26+ via brew to satisfy it.

**Context.** Reported bug, reproduced exactly: opening any `.html` file threw
`Decoration provider "start" (ns=nvim.treesitter.highlighter): ... attempt to call method 'range'
(a nil value)`, traced into `vim/treesitter/languagetree.lua` → `vim/treesitter.lua:197`
(`M.get_range`, called with a `nil` node). Root cause: `master`'s bundled `queries/html/
highlights.scm` doesn't reliably match the grammar version of the parser it installs on Neovim
0.12 — a genuine incompatibility, not a caveat. The original `master` pin was deliberate (see
[the original decision](#treesitter-branch)) specifically to *avoid* `main`'s hard requirement on
a modern `tree-sitter-cli`, which this machine's `apt` candidate (0.20.8) doesn't satisfy (needs
0.26.1+). That tradeoff turned out to be the wrong one once it actually broke editing — a
frozen/legacy branch silently accumulating incompatibility with a Neovim version it never
targeted is worse than a slightly heavier install step.

**What made `main` viable now:** `brew install tree-sitter-cli` gives 0.26.11 — satisfying the
requirement — where distro package managers don't. `install.sh` special-cases this exactly like
`lazygit` (prefer brew when available; warn with manual instructions otherwise), since apt/dnf
packages for this specific tool are misleadingly-named-but-wrong (they exist, they're just too
old to matter).

**API differences absorbed:** `main` only ships parsers/queries — highlighting is enabled
yourself, per-buffer. Rather than hand-maintain a list of every language's filetype name (which
doesn't always match the language name — `bash` the language is filetype `sh`, `vimdoc` is
filetype `help`), a catch-all `FileType` autocmd calls `pcall(vim.treesitter.start, args.buf)`
for every filetype; `vim.treesitter.start()` resolves the filetype→language mapping internally
(confirmed by reading `vim/treesitter.lua`'s `M.start`/`M.get_parser`), and the `pcall` makes it a
silent no-op wherever no parser is installed. One casualty: `main` dropped the incremental-
selection feature (`<C-space>` node-expanding selection) that `master`'s `nvim-treesitter.configs`
provided out of the box — not carried over, since it wasn't something anyone had asked for
specifically and re-implementing it by hand wasn't justified just to preserve a nice-to-have.

**The actual lesson** (beyond "verify online docs," which the [original pin
already did](#treesitter-branch)): a documented caveat ("locked but will remain available for
backward compatibility with Nvim 0.11") can be *correct as written* and *still bite you* once
your Neovim version has moved past what it was ever tested against. Re-verify a pin's tradeoffs
when something it depends on breaks — don't assume the reasoning that justified it originally
still holds indefinitely.

---

## Statusline v2: three zones, mirroring the tmux bar {#statusline-v3}

**Decision.** Restructure the statusline into three zones separated by two `%=` splits — git
branch pill on the far left, filename centered, diagnostics + language pill + position pill +
mode pill on the right — matching the left/center/right structure of the tmux bar this was
explicitly modeled on. Language (`filetype`) and cursor position (`%l:%c  %P`) are now colored
pills too, not muted grey text.

**Context.** Direct feedback after the [first pill redesign](#statusline-pills): reverse the
mode/branch positions (mode moves to the far right, branch to the far left) and make the
language/position more visually prominent, not just present. Neovim's `statusline` format
natively supports more than one `%=` — each one adds another left/right-justified split point,
so N splits produce N+1 independently-justified zones. Three zones was the natural fit for "left
thing, centered thing, right things," rather than hand-computing padding to fake center-alignment
(which the dashboard's `center()`/`center_block()` helpers do, out of necessity, since a plain
scratch buffer has no such native split mechanism — the statusline does).

**Superseded almost immediately:** the very next round of feedback moved the file path back
next to the branch (both on the left) and asked for a transparent bar background — two zones
now, not three. Documented here rather than silently editing the entry above, since the "three
zones for left/center/right" reasoning was sound for what was asked *at the time*; it just wasn't
the final shape. See below.

---

## Statusline background is also transparent, and file path moved back next to branch {#statusline-v4}

**Decision.** Back to two zones: branch pill + file path together on the left, diagnostics/
language/position/mode pills on the right. Also explicitly clear `StatusLine`/`StatusLineNC`
background (`bg = "NONE"`) so the bar has no color strip of its own — pills float directly on the
terminal's background, matching the tmux bar's look exactly.

**Context.** Direct feedback: put the file path next to the branch, and make the bar "transparent
or glass like the tmux bar." The transparent-background gap existed because onedark.nvim's own
`transparent = true` option only clears `Normal`/`SignColumn`/etc — not `StatusLine`, which most
colorschemes treat as UI chrome rather than editor background on purpose (a deliberate choice
upstream, not an oversight to work around). Confirmed by checking `vim.api.nvim_get_hl(0, {name =
"StatusLine"})` before this change: it had no explicit background set by onedark at all, meaning
it was inheriting whatever solid-color default Neovim falls back to — clearing it directly here
was the correct, and only, fix.

---

## Mason's python3-venv check needed to verify pip too, not just the venv module {#mason-venv-pip}

**Decision.** Strengthen the [earlier venv check](#mason-venv-skip): instead of testing whether
`python3 -c "import venv"` succeeds, actually create a throwaway venv and check whether `pip`
exists inside it, in both `lua/plugins/lsp.lua` and `install.sh`.

**Context.** The `ruff` install failure this was supposed to fix was still happening after the
first fix shipped. Root cause: the `venv` *module* can import successfully while `python3 -m venv`
still produces a venv with no working `pip` inside it — broken or disabled `ensurepip` is a known
issue on minimal/stripped-down Python installs. Mason's basedpyright/ruff install fails at the
*pip* step, not the *venv* step, so checking only the module import gave a false "this will work"
signal on exactly the machine that needed the warning most. The fix creates a real (throwaway,
immediately deleted) venv and checks `<venv>/bin/pip` is executable — the only way to verify what
actually matters, since there's no cheaper signal that reliably distinguishes "venv module present"
from "venv module present *and* produces a usable environment."

---

## Dashboard slogan dropped to transliteration only — the Devanagari-in-terminal risk materialized {#slogan-transliteration-only}

**Decision.** Remove the Devanagari script line from the dashboard slogan (`lua/config/
dashboard.lua`'s `SLOGANS` table); keep only the Roman transliteration + meaning.

**Context.** When [the slogan was first added](#dashboard), the choice to include Devanagari
alongside the transliteration was made with an explicit caveat noted at the time: terminals are
built around fixed-width monospace cells, which conflicts with how Devanagari's conjuncts and
reordering vowel signs actually need to be shaped, so rendering could come out garbled depending
on the terminal/font's complex-text-shaping support. That risk was flagged as *possible*, not
*confirmed*, and left in on the reasoning that the transliteration line was already there as a
safe fallback either way. It then actually happened — a real screenshot showed the Devanagari
rendering with conjuncts/vowel signs visibly out of order. Since the transliteration line already
carries the full meaning on its own, and terminal Unicode/font support can't be reliably detected
from within Neovim to conditionally show one or the other, removing the script line entirely is
the simplest fix that's correct on every terminal rather than correct on some.

---

## Floating cmdline/messages via noice.nvim, not a hand-rolled `vim.ui_attach` {#noice}

**Decision.** Add `folke/noice.nvim` (+ its one real dependency, `MunifTanjim/nui.nvim`) in
`lua/plugins/ui.lua`, configured narrowly: only `cmdline` and `messages` are taken over (view
`cmdline_popup` for the former, `mini` for the latter — `mini` specifically so a second dependency,
`nvim-notify`, isn't needed just for a nicer notify view). `lsp.hover`/`lsp.signature` are
explicitly disabled in its config, since this config already has working native bindings for both
(`K`/`<C-k>` in `lua/plugins/lsp.lua`, blink.cmp's own signature window in
`lua/plugins/completion.lua`) — letting noice take those over too would just mean two plugins
fighting over the same UI. Paired with `o.cmdheight = 0` in `lua/config/options.lua`, so the
classic bottom row collapses entirely instead of sitting empty behind the floating popup.

**Context.** The classic bottom-of-screen cmdline/message row (`:command` input, `"file" NL, NB
written` confirmations) was the one piece of chrome this config hadn't addressed, and the
requested reference point was LazyVim's floating cmdline — which *is* noice.nvim under the hood.
The other option considered was hand-rolling this directly against Neovim's own
`vim.ui_attach({ ext_cmdline = true, ext_messages = true }, ...)` API, in keeping with this
config's general "prefer native over a plugin" bias (see principle #1 in CLAUDE.md, and
`lua/config/statusline.lua`/`terminal.lua` as precedent). That bias holds for cmdline input alone —
narrow, well-scoped — but full message-subsystem parity is a much bigger surface than it looks:
`confirm()` y/n dialogs, the `--More--` pager, multi-line `:messages` history, swap-file recovery
prompts, and macro-recording indicators all route through the same mechanism, and getting any one
of them wrong risks the editor appearing to hang waiting for a keystroke the user can't see (no
visible prompt) — exactly the kind of subtle failure principle #7 ("config must survive being
deleted or corrupted") and this project's general reliability bar exist to avoid. noice.nvim has
already had years of exactly these edge cases reported and fixed upstream; reimplementing that
surface from scratch for this config would be effort spent re-discovering already-solved bugs, not
a genuine capability gain — the "hand-rolled native replacement would be a real net loss" carve-out
principle #1 itself allows for.

**Performance.** `vim.ui_attach` is event-driven — it only fires when the cmdline or a message
actually changes, so there's no per-keystroke or idle cost while editing normally; it doesn't touch
the treesitter/LSP/completion path this config has otherwise been tuned for. The two real costs are
a modest one-time plugin load (mitigated by `event = "VeryLazy"`) and a small floating-window paint
each time a message/cmdline updates — the same class of cost blink.cmp's own popup menu already
pays, and not perceptible in practice.

**Verified.** A real PTY-driven interactive test (typing `:`, then `:w`, in an actual attached
terminal) confirmed the cmdline renders as a bordered floating "Cmdline" popup, and the write
confirmation renders as a small transient popup rather than the old flush-left bottom line.

---


---

## blink.cmp's own `<Tab>`/`<CR>` mapping is unreliable — it's an `expr` mapping, evaluated under `textlock` {#blink-expr-mapping-bug}

**Decision.** Disable blink.cmp's own `<Tab>`/`<CR>` keymap entries (`["<Tab>"] = false`,
`["<CR>"] = false` in `lua/plugins/completion.lua`'s `keymap` config) and replace both with plain
(non-`expr`) mappings in `lua/config/keymaps.lua`: `accept_or_fallback(key)` calls
`blink.cmp`'s `snippet_active`/`accept`/`is_visible`/`select_and_accept`/`snippet_forward`
directly, falling through to ghost-text acceptance (`<Tab>` only) or a normal keypress via
`nvim_feedkeys` if nothing else applies.

**Context.** blink.cmp's own README-documented `keymap` presets (including `super-tab`) install
their accept/select mappings as Neovim `expr` mappings — meaning Neovim evaluates the mapping's
return value under `textlock` (the same restricted-evaluation context `expr`-mappings and some
autocmds run in). In this environment, `require('blink.cmp').is_visible()` reliably reports
stale/false specifically when called from *inside* that `textlock` context, even though the exact
same call from a plain (non-`expr`) keymap callback reads correctly — confirmed by testing both
call sites side by side, not assumed from blink's docs alone. The practical symptom: pressing
`<Tab>`/`<CR>` while a completion menu was visible would silently do nothing but insert a literal
tab/newline, as if no completion was showing at all.

**Why a second mapping instead of patching blink's own.** blink.cmp's `keymap` config doesn't
expose a way to request a non-`expr` mapping for its built-in presets — the `expr` behavior is
baked into how the preset installs itself. Disabling blink's own `<Tab>`/`<CR>` entries entirely
and mapping them directly in `keymaps.lua` (a plain callback, not `expr`) sidesteps the `textlock`
restriction altogether, since `vim.keymap.set` without `expr = true` runs in a normal execution
context. `completion.lua` setting both to `false` ensures there's only ever one mapping in play per
key — no risk of the two fighting over the same keypress.

**Alternatives considered.** Filing/waiting on an upstream fix — the `textlock` restriction on
`expr` mappings is a Neovim core behavior blink.cmp's preset runs into, not a bug in blink.cmp
itself to fix; a plain mapping on this config's own side is the correct place to work around it
regardless of upstream. Using `vim.schedule` inside the `expr` mapping to defer the
`is_visible()` check outside `textlock` — `expr` mappings must return a string synchronously, so
there's no way to defer part of the evaluation and still produce a valid return value in time.
## oil.nvim's own `q` isn't bound to close by default {#oil-q-close}

**Decision.** Add `["q"] = "actions.close"` to oil's `keymaps` table in `lua/plugins/editor.lua`.

**Context.** Oil replaces the *current buffer* with a directory listing rather than opening a
sidebar/split (this is deliberate upstream behavior, not a bug — see [the eager-loading
entry](#oil-eager) for why that same design choice mattered for lazy-loading too). Because there's
no separate window, `:q` while inside Oil closes that window like any other — and if it's the last
window, quits Neovim entirely, with no confirmation. Oil's own default keymap for "leave without
picking a file" is `<C-c>`, not `q` — but `q` is the convention every *other* file-explorer-ish
plugin (NvimTree, neo-tree, fugitive, `:messages`, help buffers) trains you to reach for, making it
an easy trap: press `<leader>e`, decide not to pick a file, reach for the muscle-memory `q`, get
nothing, try `:q` instead, and quit the whole editor. Binding `q` to oil's own `actions.close`
closes the gap without touching `<C-c>`, which still works as before.

**Verified.** A real PTY-driven interactive test (`<leader>e` to open Oil, `q` to close) confirmed
it returns to the previous buffer with Neovim still running, rather than quitting.

---

## Find files: explicit `hidden`/`ignored` + a hardcoded noise-dir exclude list, to surface `.env` {#find-files-no-ignore}

**Decision.** In `lua/plugins/editor.lua`'s `snacks.nvim` spec, set `picker.sources.files.hidden =
true`, `ignored = true`, and an explicit `exclude` list: `node_modules`, `dist`, `build`, `.next`,
`coverage`, `.venv`/`venv`, `__pycache__`, `.terraform`, `.cache` (on top of the finder's own
`.git`/`.jj` defaults).

**Context.** Reported bug: `<leader>ff` never showed `.env`. Root cause, verified empirically (not
assumed) with real `fd`/`rg` runs against a throwaway git repo: the finder's default `hidden` flag
already shows dotfiles, but nothing was passing `--no-ignore` — so anything listed in the project's
own `.gitignore` stays hidden regardless, and `.env` is almost universally gitignored. Confirmed
the two settings are genuinely independent (`--hidden` alone still hid `.env`; only also
disrespecting the ignore file surfaced it). This was originally implemented and verified against
fzf-lua's equivalent `no_ignore`/`fd_opts`/`rg_opts` options; carried over unchanged in spirit when
fzf-lua was replaced by `snacks.picker` the same session (see
[#snacks-picker-migration](#snacks-picker-migration)) — `snacks.picker.files`'s `hidden`/`ignored`/
`exclude` fields build the exact same underlying `fd`/`rg` flags (confirmed by reading
`lua/snacks/picker/source/files.lua`), so the fix and its reasoning didn't need to change, only
which plugin's option names carry it.

**Alternatives considered.**
- Disrespecting the ignore file with no manual excludes — rejected: verified with a real repo
  containing `node_modules`/`dist`, and both reappeared in full, which would make `<leader>ff`
  unusable on any real MERN project.
- ripgrep glob-override tricks (`-g '.env*'` layered over default ignore behavior) — tested first;
  an unprefixed `-g` pattern narrows results to *only* that match rather than adding it on top of
  the normal listing, so this actively broke the picker (everything else vanished) rather than
  fixing it.

**Trade-off accepted.** This trades "always exactly matches whatever this specific project's
`.gitignore` says" for "always matches this fixed list + shows genuinely gitignored files like
`.env`." A project with its own unusual gitignored noise directory not in the list above will show
it in `<leader>ff` results — acceptable since seeing a secrets file was the explicit ask and the
list above already covers this config's stated stack (MERN + DevOps + Python).

**Example.**
```lua
picker = {
  sources = {
    files = {
      hidden = true,
      ignored = true,
      exclude = { ".git", ".jj", "node_modules", "dist", "build", ".next", ... },
    },
  },
}
```

---

## File explorer: oil.nvim replaced by snacks.nvim's explorer {#snacks-explorer}

**Decision.** Replace `stevearc/oil.nvim` with `folke/snacks.nvim`'s `explorer` module
(`opts.explorer = { replace_netrw = true }`), bound to `-` and `<leader>e` via `Snacks.explorer()`.

**Context.** Explicit ask: "the most modern and feature rich" file explorer, after comparing
oil.nvim (buffer-as-filesystem editing, no tree/git/diagnostics) against neo-tree.nvim,
snacks.nvim's explorer, and mini.files. This directly reverses part of the earlier
[oil.nvim decision](#oil-eager) — that entry is left as-is above since it was the correct call
*at the time*, under a different stated priority (minimalism first). The user's own explicit
standing instruction going forward is to lead with the modern/feature-rich option even where it
costs more than the leanest native-ish choice — see the user's own words: "always prefer more
modern alternatives."

**Why snacks.nvim's explorer specifically, not neo-tree.nvim or mini.files.** Verified (not
assumed) against `folke/snacks.nvim`'s actual docs/source before committing: explorer is a
`snacks.picker` source (`lua/snacks/picker/source/explorer.lua`), not a separate tree engine, and
its real defaults (confirmed by reading `lua/snacks/picker/config/sources.lua`) already give
`git_status = true`, `diagnostics = true`, `tree = true`, a sidebar layout, and a full set of
filesystem actions (`a`/`d`/`r`/`c`/`m`/`o` for add/delete/rename/copy/move/open-externally) with
zero extra config. neo-tree.nvim would have added a second, unrelated plugin dependency purely for
the explorer; mini.files is leaner but doesn't give git-status/diagnostics badges out of the box.
Since `snacks.nvim` was already the modern choice on the table, using its bundled explorer avoided
adding a plugin at all for this — see [#snacks-picker-migration](#snacks-picker-migration) for how
this same install then also replaced the separate fuzzy-finder plugin.

**oil.nvim fully removed, not kept alongside.** Considered keeping oil for its "edit filenames as
a text buffer" bulk-rename workflow (explorer doesn't replicate that exact interaction), but the
explicit choice was full replacement — simpler keymap surface, one file-browsing mental model
instead of two. `lua/config/external.lua`'s `target_path()` (used by `<leader>ox`/`<leader>oi`)
depended on oil's `get_cursor_entry()`/`get_current_dir()` API; rewritten against
`Snacks.picker.get({source="explorer"})[1]:current()` instead — verified the item shape carries a
`.file` field by reading `snacks.picker.explorer.Item`'s class annotation, not guessed.

**Icons reintroduced.** `mini.icons` was cut once already (see
[native-statusline-terminal](#native-statusline-terminal)) on the grounds that this config had no
active use for icon glyphs. A tree explorer with per-filetype icons is a genuine, different
capability gap that reasoning didn't anticipate — re-added specifically for this, not as general
decoration. No new font requirement: this terminal was already confirmed to render Nerd Font
glyphs correctly for the statusline pills (`#statusline-pills`), and snacks' own icon fallback
(`lua/snacks/util/init.lua`, `M.icon`) always renders *some* Nerd Font glyph regardless — without
`mini.icons`/`nvim-web-devicons` it just can't pick a per-filetype one, it doesn't fall back to
plain text.

---

## Fuzzy finder: fzf-lua replaced by snacks.picker {#snacks-picker-migration}

**Decision.** Remove `ibhagwan/fzf-lua` entirely. Every call site — `<leader>ff`/`fg`/`fw`/`fb`/
`fr`/`fh`/`fd`/`fc`/`fs`/`fR`, `<leader>?`, `<leader>fK`, all six LSP picker keymaps in
`lua/plugins/lsp.lua`, the dashboard's find-files/live-grep/recent-files/grep-keybindings actions,
and harpoon's searchable mark list — moved to the equivalent `snacks.picker` source or the generic
`Snacks.picker.pick({items=...})` API for harpoon's custom list.

**Context.** Installing `snacks.nvim` for the explorer ([#snacks-explorer](#snacks-explorer))
brought `snacks.picker` — a complete second fuzzy-finder engine — in alongside the already-installed
`fzf-lua`, both actively exercised (explorer isn't dormant the way snacks' unused
dashboard/terminal/notifier modules are, since it's invoked constantly). Explicit instruction:
"remove all the overlapping plugins and keep the only needed and modern alternatives of each."
This was the one genuine overlap found in an audit of the full plugin list — every other
seemingly-competing snacks module (terminal, dashboard, notifier) is never referenced anywhere in
this config, so it stays dormant and costs nothing; only picker was actually live twice.

**Every mapping verified against real source before writing it**, not guessed from either
project's docs — `snacks.picker.config.sources` was read directly to confirm exact source names:

| fzf-lua | snacks.picker |
|---|---|
| `files()` | `files()` |
| `live_grep()` | `grep()` |
| `grep_cword()` | `grep_word()` |
| `buffers()` | `buffers()` |
| `oldfiles()` | `recent()` |
| `helptags()` | `help()` |
| `diagnostics_workspace()` | `diagnostics()` |
| `git_commits()` | `git_log()` |
| `git_status()` | `git_status()` |
| `resume()` | `resume()` |
| `keymaps()` | `keymaps()` |
| `grep_curbuf()` | `lines()` |
| `lsp_definitions/references/implementations()` | same names |
| `lsp_typedefs()` | `lsp_type_definitions()` |
| `lsp_document_symbols()` | `lsp_symbols()` |
| `lsp_live_workspace_symbols()` | `lsp_workspace_symbols()` |
| `fzf_exec(entries, {actions=...})` | `pick({items=..., actions=..., win.input.keys=...})` |

**harpoon.lua's custom list needed the most care.** fzf-lua's `fzf_exec` takes a flat list of
strings plus an `actions` table keyed by fzf bind names (`"ctrl-x"`). snacks' generic `pick()`
instead takes structured `items` (tables, not strings — `{idx=.., text=..}`), a `confirm` callback,
a named `actions` table, and a `win.input.keys` map from key to action *name* (the same pattern
snacks' own built-in `marks` source uses for its `<c-x>` delete-mark binding, confirmed by reading
`lua/snacks/picker/config/sources.lua`'s `M.marks` entry before copying its shape).

**Also fixed while migrating:** `lua/config/autocmds.lua`'s `close_with_q` autocmd listed
`"fzf-lua"` as a filetype pattern (for binding `q` to close). Dropped, not replaced with a
snacks-specific filetype — snacks pickers already bind `q` to `cancel` by default (confirmed in
`lua/snacks/picker/config/defaults.lua`), so no autocmd is needed for that anymore.

**Alternatives considered.** Keep both, leave `snacks.picker` unused outside the explorer —
rejected per the explicit "remove overlapping plugins" instruction; the redundancy (two fuzzy-list
engines resident and one of them actively used elsewhere) is exactly what was asked to be
eliminated, not a marginal case for keeping the status quo.

---

## Float transparency: onedark.nvim doesn't clear `NormalFloat`/`FloatBorder`/`Pmenu*` {#float-transparency}

**Decision.** In `lua/plugins/colorscheme.lua`, after `onedark.load()`, explicitly set
`NormalFloat`, `FloatBorder`, `Pmenu`, `PmenuSbar`, `PmenuThumb` to `bg = "none"` — gated on
`opts.transparent` so this only applies when the user has transparency on.

**Context.** Reported bug: floating panels (LSP hover, completion, pickers) showed a solid
background even with a fully transparent Kitty terminal and `onedark.nvim`'s own `transparent`
option enabled. Root cause, found by reading `onedark.nvim`'s actual source
(`lua/onedark/highlights.lua`), not assumed: almost every highlight group in that file checks
`cfg.transparent and c.none or c.bgN` — except `FloatBorder`/`NormalFloat`/`Pmenu*`, which are
hardcoded to a solid `c.bg1` regardless of the transparent setting. This is the same class of bug
this repo already hit once for the statusline background (`#statusline-v4`) — a colorscheme's
`transparent` flag not actually reaching every group a "transparent look" implies.

**Why this one fix covers so much.** Traced how floats are actually painted before writing
anything: `blink.cmp`'s `BlinkCmpMenu`/`BlinkCmpDoc`/`BlinkCmpSignatureHelp` groups link straight to
`Pmenu`/`NormalFloat` (`lua/blink/cmp/highlights.lua`), and `snacks.nvim`'s window base
(`lua/snacks/win.lua`) links its own `Normal`/`NormalNC` to `NormalFloat` too — so every snacks
picker/explorer window and blink's completion/doc/signature floats inherit this fix automatically,
not just LSP hover. `fzf-lua`'s own float groups (`FzfLuaNormal`/`FzfLuaBorder`) link to `Normal`
instead, which onedark's transparent option already handled correctly — moot now that fzf-lua is
removed ([#snacks-picker-migration](#snacks-picker-migration)), but it's why this exact bug wasn't
noticed via fzf-lua's own floats.

**On "blur."** The original ask was for a blur effect behind floating panels specifically. That's
not achievable from Neovim: blur is a property the terminal emulator (Kitty) applies to its whole
window via the OS compositor — Kitty has no visibility into where Neovim draws internal floating
windows, so it cannot selectively blur one region of its own surface. What this fix actually does
is make floats see-through to whatever Kitty is already rendering behind its own window — which
*will* be blurred if Kitty's own `background_blur` setting is enabled, uniformly, for the whole
window. There is no plugin-side equivalent to a per-float blur.

**Verified.** `vim.api.nvim_get_hl(0, {name="NormalFloat"}).bg` (and the same for `FloatBorder`/
`Pmenu`) read back `nil` after this change, confirmed headlessly — before the fix these carried a
real numeric color value inherited from onedark's `c.bg1`.

---

## Dashboard: recent projects (not files), two-column layout, and a gutter-number regression guard {#dashboard-projects}

**Decision.** Three related changes to `lua/config/dashboard.lua`:
1. The numbered quick-jump panel now lists recent **projects** (directories), not recent files.
2. That panel and "Quick actions" render side by side instead of stacked, via a new
   `side_by_side()` helper.
3. `hide_gutter()` (number/relativenumber/signcolumn/statuscolumn/cursorline) is now re-applied on
   every `BufEnter`/`WinEnter` for the dashboard buffer, not just once when it's created.

**Context, recent projects.** Explicit ask: "don't take me to specific recent files but their
folder... recent projects... identify them based on package.json." Asked directly whether a
better approach existed than a hand-rolled package.json check. It does, and it was already
installed: `snacks.picker`'s own `projects` source
(`lua/snacks/picker/source/recent.lua`'s `M.projects`) resolves each recent oldfile to its **git
root** (`Snacks.git.get_root`), which covers this config's actual stack (MERN/DevOps/Terraform
repos are all git repos) more reliably than a package.json-only check would — a Terraform-only or
plain-Makefile project without a `package.json` would otherwise be invisible. It also optionally
scans configured `dev` directories for project markers even when nothing in them has been opened
yet, which a pure oldfiles-derived list could never surface. The dashboard's own always-visible
1–5 panel (no full-picker UI needed) mirrors this with a small `project_root()` helper: git root
first via `Snacks.git.get_root`, falling back to a `package.json`/`Makefile` ancestor walk
(`vim.fs.find(..., {upward=true})`) only when a file genuinely isn't inside a git repo. The full
searchable version is exposed too — new quick action `p` calls `Snacks.picker.projects()` directly,
with `confirm` overridden away from its own `load_session` default (tailored to snacks' unused
dashboard/session modules) to `chdir` + open the explorer, matching what the numbered panel does.

**Context, two columns.** Explicit ask, given a wide terminal: "keep them in parallel... we have
more horizontal real estate." `side_by_side()` left-aligns the shorter block to the longer one's
width, joins with a gap, and the result still goes through the existing `center_block()` unchanged
— centering a two-column unit as a whole needed no new centering logic, only a way to produce the
merged lines first. Per-row keymap bindings didn't need any rework either: they're plain
buffer-local `vim.keymap.set` calls keyed by digit/letter, not scoped to the cursor's row/column,
so a project-jump key (`1`–`5`) and an unrelated action key (`f`, `g`, ...) landing on the *same*
rendered row via the merge causes no conflict.

**Context, the gutter-number bug.** Reported with a screenshot showing a numbered left gutter on
the dashboard, despite `M.open()` already setting `vim.wo.number = false` etc. right after
creating the buffer. Every headless repro attempted against the code as it stood — fresh
`VimEnter`, and manually calling `open()` from within an already-open real file with numbers
on — came back with `number=false`/`relativenumber=false` correctly, so the exact live trigger
wasn't pinned down (most likely a stale in-memory session predating some earlier fix, given
`require()` caches Lua modules and this machine's nvim-min process had been running across
multiple edits to this file this session). Rather than leave it as an unreproduced report, the fix
is made robust regardless of root cause: `hide_gutter()` was pulled into a named local function
and re-run on `BufEnter`/`WinEnter` for the dashboard buffer specifically, so nothing that runs
after buffer creation and touches these window-local options can leave the gutter showing —
cheaper than continuing to chase a repro that wouldn't reproduce.

**Alternatives considered.** For projects: a pure package.json-only walk, as originally asked —
passed over once `Snacks.git.get_root` was found already installed and doing the more general
version of the same job. For the gutter bug: doing nothing until it reproduced headlessly —
rejected, since "the code is provably correct in every scenario I could construct" isn't the same
guarantee as "this can't happen," and the fix costs nothing (a few re-applied window options on
two cheap, rarely-firing events).

**Follow-up, same session.** Two refinements after seeing it in use: swapped which side is which
(`side_by_side(action_labels, project_labels)` — actions left, projects right) per direct feedback;
and the dashboard's `k` quick action (grep `KEYBINDINGS.md`) turned out to have a real, measured
~4.6s launch delay and a visually inconsistent layout — root-caused separately, see
[#python-venv-check-latency](#python-venv-check-latency) and [#dashboard-k-grep](#dashboard-k-grep).

---

## The one-time Python venv/pip check was blocking every session's first file-open, not just the first-ever one {#python-venv-check-latency}

**Decision.** In `lua/plugins/lsp.lua`, skip `python_venv_has_pip()`'s expensive probe entirely
when `basedpyright` and `ruff` are already installed via Mason — check `mason-registry` first,
only fall through to the actual `python3 -m venv` probe if either isn't installed yet.

**Context.** Reported as "pressing `k` on the dashboard visibly takes a second." Traced with real
timing instrumentation (`vim.loop.hrtime()` around `vim.cmd.edit()`), not assumed: opening
`KEYBINDINGS.md` cold took ~4600ms. Bisected by opening *different* files first in the same
headless session — the multi-second delay followed whichever file was opened **first**, regardless
of which file or filetype, which ruled out anything specific to KEYBINDINGS.md, markdown, or
treesitter (confirmed directly by no-op'ing `vim.treesitter.start` and re-timing — no change).
`:noautocmd edit` was instant, proving it was autocmd-triggered work, not I/O. That pointed at
`nvim-lspconfig`'s lazy-load trigger (`BufReadPre`/`BufNewFile`) — its entire `config()` function,
including `python_venv_has_pip()`, only runs once per session, on whatever file happens to trigger
that event first. Timing `python3 -m venv` directly on this machine confirmed the exact cost:
**~4.3 seconds**, matching the delay almost exactly. The check (added in
[#mason-venv-skip](#mason-venv-skip) and strengthened in [#mason-venv-pip](#mason-venv-pip)) was
never wrong about *what* to check, only about paying that cost synchronously on every single
launch — including on this exact machine, where `basedpyright`/`ruff` were already installed the
entire time, which is itself proof the environment already works.

**Why this is the right cache, not a new one.** No new cache file or TTL logic needed: Mason's own
installed-package state already persists across sessions and already means "this was buildable
here at least once." Re-deriving that fact with a fresh venv on every launch was pure waste once it
had already succeeded a single time.

**Alternatives considered.** Making the probe async (`vim.system` instead of blocking
`vim.fn.system`) — more correct in the abstract (always reflects current state), but
`mason-lspconfig.setup()` immediately after depends on the synchronously-decided `ensure_installed`
list, so going async would mean deferring that whole call too — real added complexity for a check
whose result is a near-permanent machine fact, not something that changes session to session. A
disk-based cache file — rejected for the same reason Mason's own state already serves as one, at
zero extra code.

**Verified.** Timed the exact same `vim.cmd.edit()` call before/after: ~4600ms → ~113ms.

---

## Dashboard's `k` action: grep the file on disk instead of opening it as a real buffer {#dashboard-k-grep}

**Decision.** Changed the "Grep keybindings" quick action from `vim.cmd.edit(KEYBINDINGS.md)` +
`Snacks.picker.lines()` to `Snacks.picker.grep({cwd=.., glob={"KEYBINDINGS.md"}})` directly.

**Context.** Two complaints about the same action: it felt slow to open, and its picker looked
visually inconsistent with every other picker in this config (thinner, bottom-docked). The speed
complaint's real cause was the venv-check latency above, unrelated to this action specifically —
but the visual inconsistency was real and specific to this code path: `Snacks.picker.lines()`
(searching lines in the *current* buffer) defaults to the "ivy" layout preset
(`lua/snacks/picker/config/sources.lua`'s `M.lines`) — a deliberately different, bottom-anchored,
thin-bordered style, distinct from the centered/bordered "default" preset every other picker here
uses (files, grep, buffers, ...). Grepping the file on disk instead of opening it first as a real
buffer has two effects at once: it uses the same default layout as everything else (fixing the
visual complaint), and it no longer forces marksman/treesitter/gitsigns to attach to a buffer
before the picker even appears — the file only opens for real once a line is actually picked.

**Alternatives considered.** Keeping `lines()` but overriding its `layout` back to the default
preset — rejected in favor of `grep()` since it also sidesteps eagerly opening the buffer at all,
a strictly better property, not just a visual fix.

**Superseded almost immediately, same session** — see [#dashboard-keymaps-picker](#dashboard-keymaps-picker).
This fixed the *how* (layout, eager-loading) but not the *what*: grepping a markdown mirror of the
keybindings, however it's invoked, still only shows raw doc-file text rather than a structured
key/description browser. Documented here rather than edited away since the layout/eager-load
reasoning above was correct and is still why `grep()` beats `lines()` in general — it just wasn't
the right *source* for this specific action.

---

## Dashboard's `k` action: search the live keymap registry, not a doc mirror {#dashboard-keymaps-picker}

**Decision.** Changed the "Search keymaps" quick action (previously "Grep keybindings") to
`Snacks.picker.keymaps()` — the exact same picker already bound to `<leader>?`.

**Context.** Direct feedback with a screenshot: grepping `KEYBINDINGS.md` surfaces raw markdown
table rows (`| <leader>ff | Find files |`, pipes and all) as two disconnected matches per query,
not a structured "key → what it does" browser — explicitly compared to LazyVim's which-key-style
keymap search and asked for a better option. One already existed in this exact config:
`Snacks.picker.keymaps()` (source `vim_keymaps`, `format = "keymap"` in
`lua/snacks/picker/config/sources.lua`) introspects `nvim_get_keymap`-style data directly — mode,
key, `desc`, and the source file/line each mapping came from, one clean row per keymap — and was
already wired to `<leader>?` per `CLAUDE.md` principle #3, just never reused for this dashboard
action. Since every mapping in `keymaps.lua` already carries a `desc` (the same principle requires
it, specifically so this picker is useful), the result is a real per-keybinding description list,
not raw text — and it can never drift from what's actually mapped the way a markdown mirror
inevitably can.

**Alternatives considered.** Making the grep-over-markdown approach "nicer" (a custom formatter
splitting the table row into columns, e.g.) — rejected once it was clear the underlying data
source was the wrong one to begin with; polishing a search over documentation when a search over
the live keymap registry already exists and is already used elsewhere in this exact config isn't
an improvement worth making.

---

## Custom formatter for the keymaps picker: key + description only {#keymaps-picker-format}

**Decision.** In `lua/plugins/editor.lua`'s `picker.sources.keymaps`, override `format` to render
just the key (aligned) and its `desc` — dropping the built-in `keymap` formatter's mode indicator,
nowait icon, buffer number, raw rhs/the literal word `"callback"`, and truncated source file path.

**Context.** Direct feedback with a screenshot, after wiring the dashboard's `k` action to
`Snacks.picker.keymaps()` ([#dashboard-keymaps-picker](#dashboard-keymaps-picker)): the result was
still "gibberish" — a row like `n <Space>9  callback  Jump to mark 9  :nvim-min/lu...` genuinely
buries the one useful part (`Jump to mark 9`) under columns that don't mean anything without
reading the source (`"callback"` is the built-in formatter's placeholder for *any* Lua-function
keymap, which is *every* mapping in this config — see `lua/snacks/picker/format.lua`'s `M.keymap`).
This config already guarantees every mapping has a real `desc` (`CLAUDE.md` principle #3), so
that's the only field actually worth showing next to the key itself — everything else the default
formatter adds is metadata for people debugging *other* people's keymaps of unknown provenance,
not for browsing your own well-described ones.

**Verified.** Headlessly rendered several real items through the custom `format` function:
`<Esc>             Clear search highlight`, `<Space>9          Jump to mark 9`, etc. — confirmed
the actual rendered text, not just that the option was accepted without error.

**Alternatives considered.** Trimming the built-in formatter's columns one at a time via its own
config knobs — checked first; `format = "keymap"` doesn't expose per-column toggles, only a
wholesale formatter function, so a full replacement was the only option, not a preference.

---

## Keymap search backed by a generated txt export, not the live registry directly {#keymap-search-txt-export}

**Decision.** New `lua/config/keymap_search.lua`: `M.export()` walks every mode's global +
current-buffer keymaps (`vim.api.nvim_get_keymap`/`nvim_buf_get_keymap`), writes a plain
`key<TAB>description` file to `stdpath("state") .. "/nvim-min/keymaps.txt"`, and returns the same
data as a list. `M.picker()` calls `export()` fresh every time, then feeds that list straight into
`Snacks.picker.pick({items=...})` — a real generic-list picker, same pattern already used for
harpoon's mark list, not `Snacks.picker.keymaps()`. `<leader>?` and the dashboard's `k` action both
now call `keymap_search.picker()`.

**Context.** Explicit ask for a maintained txt file (key left, description right), after two
rounds of trying to fix `Snacks.picker.keymaps()`'s presentation
([#dashboard-keymaps-picker](#dashboard-keymaps-picker),
[#keymaps-picker-format](#keymaps-picker-format)). Flagged the obvious risk before building it —
a *hand*-maintained second copy of every keybinding's description would be exactly the
doc-drift problem `CLAUDE.md` principle #3 exists to prevent — and asked directly which tradeoff
to accept. Chosen: generate the txt file's content from the live registry instead of hand-typing
it, so the on-disk file is real (browsable/grep-able outside nvim, which was presumably part of
the appeal) but never drifts, since nothing is ever typed twice.

**Two real bugs found while building this, not present in the previous `Snacks.picker.keymaps()`
approach:**
- Neovim's own built-in default mappings (visual-mode `#`/`&`/`*`, etc.) carry an
  auto-generated `desc` of the literal form `:help <tag>` — not a real description, just a
  help-tag pointer. Filtered out (`desc:match("^:help ")`) since this list is specifically about
  what *this config* maps, not vanilla Vim motions.
- A single `map("v", "<", ...)` call was showing up **three times** — traced to how
  `vim.api.nvim_get_keymap`/`nvim_buf_get_keymap` report visual-mode mappings back separately
  under `"v"`, `"x"`, and `"s"` when each is queried individually, even though it was registered
  once. Deduplicating by `mode..lhs` (the obvious key) didn't catch this, since the mode letter is
  exactly what differs across the three reports. Fixed by deduplicating on `lhs..desc` instead —
  content-identical entries are the same real binding as far as this list cares, consistent with
  already having dropped mode from the display entirely.

**No preview pane.** Per direct instruction: the description is already fully visible in the row
itself, so a separate pane repeating it would be redundant. `layout = { preview = false }` — found
by reading `lua/snacks/picker/config/init.lua` (`if layout.preview == false then`) rather than
guessing at the right disable flag.

**`<cr>` still executes the mapping directly** (`vim.api.nvim_input` on the raw, non-normalized
lhs, replacing termcodes first) — preserved from the registry-backed picker's own `confirm`
behavior; the txt-based rewrite didn't need to lose that.

**Alternatives considered.** Hand-maintaining the txt file directly — the other option offered;
not chosen, for the drift reason above. Keeping `Snacks.picker.keymaps()` and only fixing its
`format` — already tried ([#keymaps-picker-format](#keymaps-picker-format)) and still wasn't what
was being asked for once the actual request (a txt-file-backed search, no preview pane) was
stated explicitly.

---

## Multi-provider AI: Gemini/OpenAI/Anthropic, chosen independently per feature {#multi-provider-ai}

**Decision.** `settings.json`'s `ai_provider` field changes shape from a single string to
`{ chat = "...", ghost_text = "..." }`. `lua/plugins/ai.lua` reads `chat` for codecompanion's
adapter and `ghost_text` (mapped through `MINUET_PROVIDER`, since minuet calls the same backend
"claude" not "anthropic") for minuet-ai's provider. `nvim-min-setup ai` manages API keys for all
three providers independently and lets you point chat and ghost text at different ones.

**Context.** Explicit ask: "make sure our setup CLI... handles all the features like setting up
the AI and its API keys," followed directly by "I should be able to choose multiple AI providers
using CLI and also add its API keys as well" when a single-active-provider design was floated
first. `ai_provider` already existed in `DEFAULTS` before this change but was completely unused —
both plugins were hardcoded to `"gemini"` regardless of its value, a half-finished feature this
closes out properly rather than leaving as dead config.

**Why per-feature, not one global provider.** codecompanion (chat) and minuet-ai (ghost text) are
already two separate plugins for two different jobs — chat prioritizes quality (on-demand, latency
matters less), ghost text prioritizes speed (ambient, latency matters most) — see
[#two-ai-plugins](#two-ai-plugins). Since they're already independent, a single global "active
provider" would have been an artificial constraint (e.g. wanting Claude's chat quality but
Gemini-flash's ghost-text latency) the architecture doesn't actually require.

**Naming/env-var mapping, verified against both plugins' source, not assumed:**

| This config's id | codecompanion adapter | minuet-ai provider | env var (both agree) |
|---|---|---|---|
| `gemini` | `gemini` | `gemini` | `GEMINI_API_KEY` |
| `openai` | `openai` | `openai` | `OPENAI_API_KEY` |
| `anthropic` | `anthropic` | `claude` | `ANTHROPIC_API_KEY` |

Only minuet's naming diverges (`claude` vs. `anthropic` for the same backend) — both plugins
otherwise agree on env var names, so `secrets.env`'s shape needed no per-plugin translation, only
`MINUET_PROVIDER` in `lua/plugins/ai.lua`.

**Model overrides stay Gemini-specific.** The existing `gemini-2.5-pro` (chat) /
`gemini-2.0-flash` + `thinkingBudget=0` (ghost text) overrides were kept scoped to
`provider == "gemini"` rather than generalized — they exist because Gemini's own defaults in each
plugin didn't fit (codecompanion's gemini adapter defaults lighter than wanted for chat; minuet's
own docs recommend disabling thinking for line completion). OpenAI/Anthropic get each plugin's own
defaults (`gpt-5.4-nano`/`claude-haiku-4-5` for minuet, each adapter's own default chat model for
codecompanion) since nothing established those need overriding — inventing tuning without the
same kind of measured justification the Gemini overrides had would be scope creep, not parity.

**Live key verification, not blind trust.** `nvim-min-setup ai` makes one real, short-timeout
(6s) authenticated request per provider before saving a key (`GET .../v1beta/models` for Gemini,
`GET .../v1/models` for OpenAI/Anthropic) — a rejected key is flagged with an explicit "save
anyway?" instead of silently accepting a typo'd or revoked key and only finding out inside nvim
later. A network failure (not a rejection) is treated differently: warns and saves anyway, since
offline isn't evidence the key is bad.

**Backward compatible.** A pre-existing `settings.json` with `ai_provider` as a plain string
(the old shape) is migrated to `{chat: <value>, ghost_text: <value>}` on load — implemented
identically on both sides (`lua/config/user_settings.lua` and `bin/nvim-min-setup`), since neither
can assume the other has already normalized it.

**Alternatives considered.** One global `ai_provider` string with a single "active" concept, just
extended to 3 values instead of a hardcoded "gemini" — rejected once the per-feature independence
was recognized as the actually-useful shape, not extra complexity for its own sake. A `.env`-style
free-form provider list — rejected in favor of a small fixed set (gemini/openai/anthropic) matched
exactly to what both AI plugins already support well, rather than building a generic plugin
system for providers nothing here uses yet.

---

## `nvim-min-setup doctor`: a real preflight check, not just install.sh's job repeated blind faith {#setup-cli-doctor}

**Decision.** New `nvim-min-setup doctor` command: checks git/curl/ripgrep/fd/lazygit/Neovim
0.12+/tree-sitter-cli 0.26+/python3-venv+pip/brew (mirroring `install.sh`'s own requirement list),
plus whether `settings.json` parses and `secrets.env` has `0600` permissions.

**Context.** Same "foolproof" ask that drove the multi-provider work. `install.sh` already checks
and *installs* these on a fresh clone, but there was no way to re-verify system state afterward —
if a tool got uninstalled, a permission got changed by hand, or someone's `PATH` changed, the only
way to find out was a confusing failure somewhere else (Mason retry-failing silently, `<leader>ff`
using a slower fallback with no explanation, etc). `doctor` surfaces the same facts on demand,
without re-running any installation.

**Why it doesn't fix anything itself.** Deliberately read-only — `install.sh` already owns
"detect + install," and duplicating that logic in the CLI would be two places that could drift
out of sync about what "fixed" means for a given tool (e.g. `install.sh`'s brew-preference logic
for tree-sitter-cli/python). `doctor` just points back at `./install.sh` when something's missing.

**Verified.** Ran on this machine: all checks report a real, currently-true result (`fd`
installed, `tree-sitter-cli 0.26`, Neovim 0.12.4, working venv+pip, `brew` present) — not
hand-waved, actually executed and read back.

---
