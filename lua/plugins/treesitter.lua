return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  opts = {
    ensure_installed = {
      "javascript", "typescript", "tsx", "html", "css", "json", "jsonc",
      "yaml", "toml", "dockerfile", "terraform", "hcl", "bash", "lua",
      "python", "markdown", "markdown_inline", "gitignore", "git_config",
      "gitcommit", "diff", "regex", "vim", "vimdoc", "query", "graphql",
    },
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-space>",
        node_incremental = "<C-space>",
        node_decremental = "<bs>",
      },
    },
  },
  config = function(_, opts)
    require("nvim-treesitter.configs").setup(opts)
  end,
}
