return {
  {
    -- Replaces both oil.nvim (file explorer) and fzf-lua (fuzzy finder) — see
    -- docs/decisions/index.md#snacks-explorer and #snacks-picker-migration.
    -- Explorer and every finder below are all `snacks.picker` sources under
    -- the hood, one engine instead of two. Other snacks modules (dashboard,
    -- notifier, terminal, ...) are never referenced anywhere in this config,
    -- so they stay dormant — this config already has native replacements for
    -- those, see CLAUDE.md principle #1.
    "folke/snacks.nvim",
    lazy = false,
    opts = {
      explorer = { replace_netrw = true },
      picker = {
        sources = {
          files = {
            -- `.env` is almost always gitignored, and the ignore-file is
            -- respected by default — same root cause/fix as fzf-lua's
            -- equivalent option before it, see #find-files-no-ignore.
            hidden = true,
            ignored = true,
            exclude = {
              ".git", ".jj", "node_modules", "dist", "build", ".next",
              "coverage", ".venv", "venv", "__pycache__", ".terraform", ".cache",
            },
          },
        },
      },
    },
  },
  {
    -- Icon provider for snacks' explorer/picker file icons. Reintroduced
    -- deliberately (mini.icons was cut earlier alongside mini.statusline —
    -- see docs/decisions/index.md#native-statusline-terminal) because a tree
    -- explorer with per-filetype icons is a genuine capability gap a native
    -- replacement can't close; this config's terminal (kitty) already
    -- renders Nerd Font glyphs correctly (confirmed for the statusline pills,
    -- #statusline-pills), so there's no new font requirement.
    "nvim-mini/mini.icons",
    lazy = false,
    opts = {},
  },
  {
    "nvim-mini/mini.pairs",
    event = "InsertEnter",
    opts = {},
  },
  {
    "nvim-mini/mini.surround",
    keys = { "sa", "sd", "sr", "sf", "sF", "sh", "sn" },
    opts = {},
  },
}
