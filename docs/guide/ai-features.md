# AI features

Both plugins support Gemini, OpenAI, and Anthropic — chosen independently for each, via
[the setup CLI](/guide/setup-cli) (`nvim-min-setup ai`). Both are individually toggleable, and
neither is loaded at all when disabled — see
[Decision history → Two AI plugins, not one](/decisions/#two-ai-plugins) and
[→ Multi-provider AI](/decisions/#multi-provider-ai).

## Chat & inline assistant — codecompanion.nvim

| Key | Action |
|---|---|
| `<leader>aa` | Toggle chat |
| `<leader>ac` | Actions palette |
| `<leader>aA` (visual) | Add selection to chat |
| `<leader>ai` | Inline prompt — type a task, `<cr>` |

Provider: whichever `nvim-min-setup ai` has chat set to. On Gemini specifically, the model is
pinned to `gemini-2.5-pro` (quality matters more than latency for an on-demand chat/edit tool);
OpenAI/Anthropic use codecompanion's own defaults. Configured in `lua/plugins/ai.lua`.

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

Model: on Gemini, `gemini-2.0-flash` with thinking disabled (`thinkingBudget = 0`) — the 2.5
models' extended thinking mode adds latency with no benefit for line completion, per minuet-ai's
own docs. OpenAI/Anthropic use minuet's own fast defaults (`gpt-5.4-nano` / `claude-haiku-4-5`) —
already the right tradeoff for this job, no override needed.

### Why `<Tab>`/`<CR>` don't fight blink.cmp

Both keys are bound once in `lua/config/keymaps.lua` (`accept_or_fallback`), not by blink.cmp's
own `keymap` preset — blink's own `<Tab>`/`<CR>` entries are explicitly disabled
(`["<Tab>"] = false` / `["<CR>"] = false` in `lua/plugins/completion.lua`) because they're `expr`
mappings, evaluated under `textlock`, where `blink.cmp.is_visible()` unreliably reads back
stale/false — see
[Decision history → blink.cmp's own Tab/CR mapping is unreliable](/decisions/#blink-expr-mapping-bug)
for the full story. `accept_or_fallback` tries blink's snippet/completion actions first, then
ghost text, then falls through to a normal keypress — a single plain (non-`expr`) mapping per
key, so there's only ever one handler in play for `<Tab>`/`<CR>`, not two fighting over it.
