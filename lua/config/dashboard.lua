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

--- Open a recent project: cd into it and land in the file explorer there,
--- rather than any specific file inside it.
local function open_project(dir)
  vim.fn.chdir(dir)
  require("snacks").explorer({ cwd = dir })
end

--- Buffer-local action, bound to a single key on the dashboard buffer.
---@type {key: string, desc: string, action: fun()}[]
local ACTIONS = {
  { key = "f", desc = "Find files", action = function() require("snacks").picker.files() end },
  { key = "g", desc = "Live grep", action = function() require("snacks").picker.grep() end },
  { key = "r", desc = "Recent files", action = function() require("snacks").picker.recent() end },
  {
    key = "p",
    desc = "Recent projects",
    action = function()
      -- snacks.picker's own `projects` source (lua/snacks/picker/source/recent.lua,
      -- M.projects): recent oldfiles resolved to their git root, plus a scan
      -- of `dev` dirs for anything matching `patterns` (.git, package.json,
      -- Makefile, ...) — broader and already-verified vs. hand-rolling the
      -- same git-root walk twice. Its own `confirm` default is
      -- `load_session`, tailored to snacks' own dashboard/session modules
      -- this config doesn't use; override it to match `open_project` below.
      require("snacks").picker.projects({
        confirm = function(picker, item)
          picker:close()
          if item then open_project(item.file) end
        end,
      })
    end,
  },
  { key = "e", desc = "File manager", action = function() require("snacks").explorer() end },
  {
    key = "k",
    desc = "Search keymaps",
    action = function() require("config.keymap_search").picker() end,
  },
  { key = "a", desc = "AI chat", action = function() vim.cmd("CodeCompanionChat Toggle") end },
  { key = "n", desc = "New file", action = function() vim.cmd.enew() end },
  { key = "q", desc = "Quit", action = function() vim.cmd.quit() end },
}

--- Nearest project root for a file: git root first (covers everything this
--- config's stack cares about — MERN, DevOps, Terraform repos are all git
--- repos), falling back to the nearest ancestor with package.json/Makefile
--- for the rare non-git case. Reuses `snacks.git`'s own root-finder instead
--- of re-walking the same parent chain twice.
local function project_root(file)
  local ok, root = pcall(function() return require("snacks").git.get_root(file) end)
  if ok and root then return root end
  local marker = vim.fs.find({ "package.json", "Makefile" }, { path = vim.fs.dirname(file), upward = true })[1]
  return marker and vim.fs.dirname(marker) or nil
end

local function recent_projects(limit)
  local seen = {}
  local projects = {}
  for _, file in ipairs(vim.v.oldfiles) do
    if #projects >= limit then break end
    if vim.fn.filereadable(file) == 1 then
      local root = project_root(file)
      if root and not seen[root] then
        seen[root] = true
        table.insert(projects, root)
      end
    end
  end
  return projects
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

-- Lay two blocks of lines out side by side (left column left-aligned to its
-- own widest line, then a gap, then the right column) instead of stacking
-- them — there's horizontal room to spare and stacking wastes it. Shorter
-- column is padded with blank lines so both end at the same row. The merged
-- result still goes through `center_block` afterwards like any other block,
-- so the whole two-column unit centers as one.
local function side_by_side(left, right, gap)
  gap = string.rep(" ", gap or 6)
  local left_w = 0
  for _, l in ipairs(left) do
    left_w = math.max(left_w, vim.fn.strdisplaywidth(l))
  end
  local height = math.max(#left, #right)
  local out = {}
  for i = 1, height do
    local l = left[i] or ""
    local r = right[i] or ""
    if r == "" then
      table.insert(out, l)
    else
      table.insert(out, l .. string.rep(" ", left_w - vim.fn.strdisplaywidth(l)) .. gap .. r)
    end
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

  -- Recent projects (left) and quick actions (right), side by side — plenty
  -- of horizontal room for it, and it used to just stack these vertically.
  local projects = recent_projects(5)
  local project_labels = { "Recent projects" }
  for i, dir in ipairs(projects) do
    project_labels[i + 1] = string.format("%d  %s", i, vim.fn.fnamemodify(dir, ":~"))
  end

  local action_labels = { "Quick actions" }
  for i, item in ipairs(ACTIONS) do
    action_labels[i + 1] = string.format("%s  %s", item.key, item.desc)
  end

  local merged = side_by_side(action_labels, project_labels)
  for i, line in ipairs(center_block(merged, win_width)) do
    table.insert(lines, line)
    if i == 1 then
      table.insert(highlights, { line = #lines - 1, hl_group = "DashboardHeading" })
    else
      local dir = projects[i - 1]
      if dir then
        table.insert(keymap_lines, { line = #lines - 1, key = tostring(i - 1), dir = dir })
      end
      local item = ACTIONS[i - 1]
      if item then
        table.insert(keymap_lines, { line = #lines - 1, key = item.key, action = item.action })
      end
    end
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

  local function hide_gutter()
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
    vim.wo.cursorline = false
    vim.wo.statuscolumn = ""
    -- hide the trailing ~ end-of-buffer markers below the content — a stack
    -- of them under a dashboard reads as visual clutter, not a real editing view
    vim.opt_local.fillchars:append({ eob = " " })
  end

  vim.api.nvim_set_current_buf(buf)
  hide_gutter()

  -- Belt-and-suspenders: re-apply on every BufEnter/WinEnter for this buffer,
  -- not just once at creation. These are WINDOW-local options, so anything
  -- that touches them on the current window after this point (a deferred
  -- plugin callback, re-entering this buffer from a split, ...) would
  -- otherwise leave the numbered gutter showing on the dashboard.
  vim.api.nvim_create_autocmd({ "BufEnter", "WinEnter" }, {
    buffer = buf,
    callback = hide_gutter,
  })

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
    elseif k.dir then
      vim.keymap.set("n", k.key, function() open_project(k.dir) end,
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
