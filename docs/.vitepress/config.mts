import { defineConfig } from "vitepress";

export default defineConfig({
  title: "nvim-min",
  description: "A minimal, fast Neovim config for MERN + DevOps + Gen AI",
  cleanUrls: true,
  lastUpdated: true,

  // KEYBINDINGS.md (included verbatim in guide/keybindings.md) links to repo
  // source files with plain relative paths — correct on GitHub, not a docs
  // route. Only ignore source-file extensions, not doc-to-doc links.
  ignoreDeadLinks: [/\.(lua|sh)$/],

  themeConfig: {
    nav: [
      { text: "Guide", link: "/guide/getting-started" },
      { text: "Decisions", link: "/decisions/" },
      { text: "GitHub", link: "https://github.com/nimapdevyash/nvim-min" },
    ],

    sidebar: [
      {
        text: "Guide",
        items: [
          { text: "Getting started", link: "/guide/getting-started" },
          { text: "Switching configs", link: "/guide/switching-configs" },
          { text: "The setup CLI", link: "/guide/setup-cli" },
          { text: "AI features", link: "/guide/ai-features" },
          { text: "LSP & performance", link: "/guide/lsp-and-performance" },
          { text: "Keybindings", link: "/guide/keybindings" },
          { text: "Outsourcing to CLI tools", link: "/guide/outsourcing" },
        ],
      },
      {
        text: "Decisions",
        items: [{ text: "Decision history", link: "/decisions/" }],
      },
    ],

    socialLinks: [{ icon: "github", link: "https://github.com/nimapdevyash/nvim-min" }],

    search: { provider: "local" },

    footer: {
      message: "Docs must stay in sync with the code — see CLAUDE.md.",
    },
  },
});
