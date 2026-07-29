# AI features

Both are Gemini-backed, individually toggleable from [the setup CLI](/guide/setup-cli), and
neither is loaded at all when disabled — see
[Decision history → Two AI plugins, not one](/decisions/#two-ai-plugins).

## Chat & inline assistant — codecompanion.nvim

| Key | Action |
|---|---|
| `<leader>aa` | Toggle chat |
| `<leader>ac` | Actions palette |
| `<leader>aA` (visual) | Add selection to chat |
| `<leader>ai` | Inline prompt — type a task, `<cr>` |

Model: `gemini-2.5-pro` (quality matters more than latency for an on-demand chat/edit tool).
Configured in `lua/plugins/ai.lua`.

## Ghost text — minuet-ai.nvim

Copilot-style inline suggestions as you type, in `javascript`/`typescript`/`(t|j)sx`, `python`,
`lua`, `sh`, `yaml`, `dockerfile`, `terraform`, `json`, `html`, `css` — the languages this config
targets, not every filetype (see `auto_trigger_ft` in `lua/plugins/ai.lua` to add more).

| Key | Action |
|---|---|
| `<Tab>` | Accept the whole suggestion — falls through to blink.cmp's normal `<Tab>` when nothing is showing |
| `<A-a>` | Accept one line only |
| `<A-z>` | Accept N lines (prompts for a count) |
| `<A-]>` / `<A-[>` | Cycle to next / previous suggestion |
| `<A-e>` | Dismiss |
| `<leader>at` | Toggle ghost text for **this session only** |

Model: `gemini-2.0-flash`, thinking disabled (`thinkingBudget = 0`) — the 2.5 models' extended
thinking mode adds latency with no benefit for line completion, per minuet-ai's own docs.

### Why `<Tab>` doesn't fight blink.cmp

blink.cmp's `super-tab` preset already ends its own `<Tab>` handler chain with a `fallback` step
that dynamically re-resolves whatever global `<i>`-mode `<Tab>` mapping existed *at the moment
it's invoked* (verified by reading `blink.cmp`'s own `keymap/fallback.lua` — it re-checks
`get_non_blink_global_mapping_for_key` on every call, not just once at registration time). So the
ghost-text handler in `keymaps.lua` is registered as a completely ordinary global mapping, and
blink chains to it automatically whenever its own menu-select/snippet-jump don't apply. No custom
glue beyond that one `expr = true` mapping was needed.
