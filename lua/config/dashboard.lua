-- Native start screen, no plugin (no alpha.nvim / dashboard.nvim / snacks).
-- Shown once on VimEnter when nvim opens with no file arguments, exactly
-- like those plugins — built from a scratch buffer + vim.v.oldfiles, nothing
-- else.
local M = {}

-- figlet -f doom YASH, trailing whitespace trimmed, verified byte-for-byte
local LOGO = {
  "__   _____   _____ _   _",
  "\\ \\ / / _ \\ /  ___| | | |",
  " \\ V / /_\\ \\\\ `--.| |_| |",
  "  \\ /|  _  | `--. \\  _  |",
  "  | || | | |/\\__/ / | | |",
  "  \\_/\\_| |_/\\____/\\_| |_/",
}

local TAGLINE = "nvim-min · MERN + DevOps + Gen AI"

-- Transliteration only, not the Devanagari script — terminals are built
-- around fixed-width monospace cells, which conflicts with how Devanagari
-- conjuncts and reordering vowel signs actually need to be shaped. Confirmed
-- broken (garbled glyph order) in real use rather than left as a
-- theoretical risk. Extensible on purpose — add more here and the random
-- pick below just works.
local SLOGANS = {
  { text = "Vīrabhogyā Vasundharā", sub = "the earth is enjoyed by the brave" },
}

math.randomseed(vim.uv.hrtime())
local function pick_slogan()
  return SLOGANS[math.random(#SLOGANS)]
end

--- Buffer-local action, bound to a single key on the dashboard buffer.
---@type {key: string, desc: string, action: fun()}[]
local ACTIONS = {
  { key = "f", desc = "Find files", action = function() require("fzf-lua").files() end },
  { key = "g", desc = "Live grep", action = function() require("fzf-lua").live_grep() end },
  { key = "r", desc = "Recent files", action = function() require("fzf-lua").oldfiles() end },
  { key = "e", desc = "File manager", action = function() vim.cmd.Oil() end },
  { key = "a", desc = "AI chat", action = function() vim.cmd("CodeCompanionChat Toggle") end },
  { key = "n", desc = "New file", action = function() vim.cmd.enew() end },
  { key = "q", desc = "Quit", action = function() vim.cmd.quit() end },
}

local function recent_files(limit)
  local files = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #files >= limit then break end
    if vim.fn.filereadable(file) == 1 then
      table.insert(files, file)
    end
  end
  return files
end

local function center(line, width)
  local pad = math.max(0, math.floor((width - vim.fn.strdisplaywidth(line)) / 2))
  return string.rep(" ", pad) .. line
end

-- Pads every logo line to the SAME left margin (based on the widest line),
-- so the block stays visually aligned instead of each line centering
-- independently and drifting sideways relative to its neighbours.
local function center_block(lines, width)
  local max_w = 0
  for _, line in ipairs(lines) do
    max_w = math.max(max_w, vim.fn.strdisplaywidth(line))
  end
  local pad = string.rep(" ", math.max(0, math.floor((width - max_w) / 2)))
  local out = {}
  for _, line in ipairs(lines) do
    table.insert(out, pad .. line)
  end
  return out
end

function M.open()
  local win_width = vim.api.nvim_win_get_width(0)
  local win_height = vim.api.nvim_win_get_height(0)

  local lines = {}
  local highlights = {} -- {line = i, hl_group = "..."}
  local keymap_lines = {} -- {line = i, key = "f"}

  vim.list_extend(lines, center_block(LOGO, win_width))
  for i = 1, #LOGO do
    table.insert(highlights, { line = i - 1, hl_group = "DashboardLogo" })
  end

  table.insert(lines, "")
  table.insert(lines, center(TAGLINE, win_width))
  table.insert(highlights, { line = #lines - 1, hl_group = "DashboardTagline" })
  table.insert(lines, "")
  table.insert(lines, "")

  local recents = recent_files(5)
  if #recents > 0 then
    table.insert(lines, center("Recent files", win_width))
    table.insert(highlights, { line = #lines - 1, hl_group = "DashboardHeading" })

    local labels = {}
    for i, file in ipairs(recents) do
      labels[i] = string.format("%d  %s", i, vim.fn.fnamemodify(file, ":~:."))
    end
    for i, line in ipairs(center_block(labels, win_width)) do
      table.insert(lines, line)
      table.insert(keymap_lines, { line = #lines - 1, key = tostring(i), path = recents[i] })
    end
    table.insert(lines, "")
  end

  table.insert(lines, center("Quick actions", win_width))
  table.insert(highlights, { line = #lines - 1, hl_group = "DashboardHeading" })

  local action_labels = {}
  for i, item in ipairs(ACTIONS) do
    action_labels[i] = string.format("%s  %s", item.key, item.desc)
  end
  for i, line in ipairs(center_block(action_labels, win_width)) do
    table.insert(lines, line)
    table.insert(keymap_lines, { line = #lines - 1, key = ACTIONS[i].key, action = ACTIONS[i].action })
  end

  local slogan = pick_slogan()
  table.insert(lines, "")
  table.insert(lines, "")
  table.insert(lines, center(slogan.text, win_width))
  table.insert(highlights, { line = #lines - 1, hl_group = "DashboardSlogan" })
  table.insert(lines, center(slogan.sub, win_width))
  table.insert(highlights, { line = #lines - 1, hl_group = "DashboardSloganSub" })

  local top_pad = math.max(0, math.floor((win_height - #lines) / 2) - 2)
  for _ = 1, top_pad do
    table.insert(lines, 1, "")
    for _, h in ipairs(highlights) do
      h.line = h.line + 1
    end
    for _, k in ipairs(keymap_lines) do
      k.line = k.line + 1
    end
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "dashboard"
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].swapfile = false

  vim.api.nvim_set_current_buf(buf)
  vim.wo.number = false
  vim.wo.relativenumber = false
  vim.wo.signcolumn = "no"
  vim.wo.cursorline = false
  vim.wo.statuscolumn = ""
  -- hide the trailing ~ end-of-buffer markers below the content — a stack of
  -- them under a dashboard reads as visual clutter, not a real editing view
  vim.opt_local.fillchars:append({ eob = " " })

  -- number/relativenumber/etc are WINDOW-local, not buffer-local — leaving
  -- them off here would otherwise leak into whatever real file gets opened
  -- next in this same window (e.g. via one of the quick actions above),
  -- silently killing line numbers everywhere until a new split is made.
  vim.api.nvim_create_autocmd({ "BufLeave", "BufWipeout" }, {
    buffer = buf,
    once = true,
    callback = function()
      vim.wo.number = true
      vim.wo.relativenumber = true
      vim.wo.signcolumn = "yes"
      vim.wo.cursorline = true
      vim.wo.statuscolumn = ""
      vim.opt_local.fillchars:remove("eob")
    end,
  })

  local ns = vim.api.nvim_create_namespace("dashboard")
  for _, h in ipairs(highlights) do
    vim.api.nvim_buf_add_highlight(buf, ns, h.hl_group, h.line, 0, -1)
  end

  for _, k in ipairs(keymap_lines) do
    if k.path then
      vim.keymap.set("n", k.key, function() vim.cmd.edit(vim.fn.fnameescape(k.path)) end,
        { buffer = buf, silent = true, nowait = true })
    elseif k.action then
      vim.keymap.set("n", k.key, k.action, { buffer = buf, silent = true, nowait = true })
    end
  end

  -- park the cursor on the first interactive line rather than at (0,0)
  if keymap_lines[1] then
    vim.api.nvim_win_set_cursor(0, { keymap_lines[1].line + 1, 0 })
  end
end

function M.setup_highlights()
  vim.api.nvim_set_hl(0, "DashboardLogo", { link = "Title", default = true })
  vim.api.nvim_set_hl(0, "DashboardTagline", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "DashboardHeading", { link = "Function", bold = true, default = true })
  vim.api.nvim_set_hl(0, "DashboardSlogan", { link = "String", bold = true, default = true })
  vim.api.nvim_set_hl(0, "DashboardSloganSub", { link = "Comment", italic = true, default = true })
end

return M
