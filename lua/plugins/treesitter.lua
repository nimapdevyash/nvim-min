-- `main`, not `master`: the legacy `master` branch's bundled queries don't
-- reliably match the parser versions it installs on Neovim 0.12 — confirmed
-- by a real crash (`attempt to call method 'range' (a nil value)` in
-- vim/treesitter.lua, opening any .html file). See decision history for the
-- full story, including why `master` was picked initially and what changed.
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false, -- upstream is explicit: "This plugin does not support lazy-loading"
  build = ":TSUpdate",
  config = function()
    local ensure_installed = {
      -- no separate "jsonc" parser exists — vim.treesitter.language.get_lang
      -- ("jsonc") already resolves to "json", confirmed directly
      "javascript", "typescript", "tsx", "html", "css", "json",
      "yaml", "toml", "dockerfile", "terraform", "hcl", "bash", "lua",
      "python", "markdown", "markdown_inline", "gitignore", "git_config",
      "gitcommit", "diff", "regex", "vim", "vimdoc", "query", "graphql",
    }
    require("nvim-treesitter").install(ensure_installed)

    -- `main` only ships parsers/queries — highlighting is enabled per-buffer
    -- yourself (per the plugin's own README). A catch-all FileType autocmd
    -- rather than an explicit filetype list sidesteps language-name vs.
    -- filetype-name mismatches (e.g. the "bash" *language* is filetype
    -- "sh") since vim.treesitter.start() resolves that internally; pcall
    -- makes it a silent no-op wherever a parser genuinely isn't installed.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_start", { clear = true }),
      callback = function(args) pcall(vim.treesitter.start, args.buf) end,
    })
  end,
}
