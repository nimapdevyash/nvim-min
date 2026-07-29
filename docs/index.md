---
layout: home

hero:
  name: nvim-min
  text: Minimal, fast Neovim for MERN + DevOps + Gen AI
  tagline: Every plugin earns its place. Everything else is native — or outsourced to a CLI tool that already does it better.
  actions:
    - theme: brand
      text: Get started
      link: /guide/getting-started
    - theme: alt
      text: Why these decisions?
      link: /decisions/
    - theme: alt
      text: GitHub
      link: https://github.com/nimapdevyash/nvim-min

features:
  - title: Genuinely minimal
    details: 12 plugins, each justified against "can Neovim already do this?" Statusline, floating terminal, and image preview are native Lua or a shelled-out CLI tool, not plugins.
  - title: Fast LSP, on purpose
    details: Semantic tokens disabled (treesitter already highlights), inlay hints opt-in, debounced text-change notifications — Zed-inspired discipline about what triggers LSP work.
  - title: Gemini, native to the editor
    details: codecompanion.nvim for chat + inline assist, minuet-ai.nvim for Copilot-style ghost text — both individually toggleable at zero startup cost.
  - title: Config decoupled from the editor
    details: nvim-min never prompts you for anything. All setup — API keys, theme, feature toggles — lives in a separate CLI, nvim-min-setup.
  - title: Switch configs like switching Node versions
    details: nvims is an nvm-style picker across every ~/.config/nvim* config on the machine, built on Neovim's native NVIM_APPNAME.
  - title: Every non-obvious call, explained
    details: The Decision history logs what we chose and why — pinned versions, cut plugins, native replacements — so nobody re-litigates a settled question or silently regresses one.
---
