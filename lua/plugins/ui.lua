return {
  "folke/noice.nvim",
  -- Needs to see the very first cmdline/message, so it can't wait for an
  -- editing event like InsertEnter the way completion.lua's blink.cmp does.
  event = "VeryLazy",
  dependencies = { "MunifTanjim/nui.nvim" },
  opts = {
    cmdline = {
      -- "cmdline_popup" (the default) is the floating, centered box this was
      -- added for — set here anyway so a future noice default change can't
      -- silently regress the thing this file exists for.
      view = "cmdline_popup",
    },
    messages = {
      -- Plain messages (":w" confirmations, "search hit BOTTOM", etc.) —
      -- these are what used to sit on that bottom line. "mini" is a small
      -- transient corner popup that auto-dismisses; avoids adding
      -- nvim-notify as a second dependency just for a nicer notify view.
      view = "mini",
      view_error = "mini",
      view_warn = "mini",
    },
    notify = { view = "mini" },
    lsp = {
      -- Hover/signature already have native, working bindings (K, <C-k> —
      -- see lua/plugins/lsp.lua and blink.cmp's own signature window in
      -- completion.lua). Only take over cmdline + messages; don't make
      -- noice fight either of them for the same UI.
      hover = { enabled = false },
      signature = { enabled = false },
      message = { enabled = true, view = "mini" },
      progress = { enabled = true, view = "mini" },
    },
    presets = {
      -- Route anything long (:messages, multi-line errors) to a scratch
      -- split instead of the old `--More--` pager prompt, which blocks
      -- editing until you dismiss it by hand.
      long_message_to_split = true,
    },
  },
}
