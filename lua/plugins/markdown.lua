-- Renders markdown in-buffer (headings, tables, checkboxes, code blocks,
-- callouts) instead of showing raw syntax — treesitter highlighting alone
-- colors the text but doesn't reflow tables or hide `#`/`-`/backtick markup.
-- No native equivalent for that. Uses mini.icons (already installed for
-- snacks' explorer/picker, see editor.lua) for code-block language icons —
-- no new icon-font dependency.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  ft = "markdown",
  dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
  opts = {},
}
