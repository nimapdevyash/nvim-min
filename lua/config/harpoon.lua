-- Harpoon-style numbered file marks, no plugin. Marks persist per-project
-- (keyed by cwd) to stdpath("state"), so they survive restarts the same way
-- real harpoon.nvim's marks do — this isn't a plugin-free imitation of the
-- ordering/recency behavior, it's the actual "pin these files, jump by
-- number" workflow.
local M = {}

local function store_path()
  local dir = vim.fn.stdpath("state") .. "/harpoon"
  vim.fn.mkdir(dir, "p")
  -- sha256 of cwd keeps the filename short and filesystem-safe regardless
  -- of what characters are in the project path
  return dir .. "/" .. vim.fn.sha256(vim.fn.getcwd()) .. ".json"
end

local function load()
  local f = io.open(store_path(), "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  local ok, decoded = pcall(vim.json.decode, content)
  return (ok and type(decoded) == "table") and decoded or {}
end

local function save(marks)
  local f = io.open(store_path(), "w")
  if not f then return end
  f:write(vim.json.encode(marks))
  f:close()
end

--- Add the current buffer's file to the end of the mark list.
function M.add()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return vim.notify("harpoon: no file in this buffer", vim.log.levels.WARN)
  end

  local marks = load()
  for _, p in ipairs(marks) do
    if p == path then
      return vim.notify("harpoon: already marked", vim.log.levels.INFO)
    end
  end
  table.insert(marks, path)
  save(marks)
  vim.notify(string.format("harpoon: marked (%d)", #marks), vim.log.levels.INFO)
end

--- Remove the current buffer's file from the mark list, if present.
function M.remove()
  local path = vim.api.nvim_buf_get_name(0)
  local marks = load()
  for i, p in ipairs(marks) do
    if p == path then
      table.remove(marks, i)
      save(marks)
      return vim.notify("harpoon: unmarked", vim.log.levels.INFO)
    end
  end
  vim.notify("harpoon: this file isn't marked", vim.log.levels.WARN)
end

--- Jump straight to mark N — the whole point of numbering them.
function M.jump(index)
  local marks = load()
  local path = marks[index]
  if not path then
    return vim.notify("harpoon: no mark " .. index, vim.log.levels.WARN)
  end
  if vim.fn.filereadable(path) == 0 then
    return vim.notify("harpoon: " .. path .. " no longer exists", vim.log.levels.WARN)
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end

--- Fuzzy-searchable list of marks (snacks.picker gives us the "search them"
--- part for free — no separate picker UI to build). <cr> jumps, ctrl-x removes.
function M.list()
  local marks = load()
  if #marks == 0 then
    return vim.notify("harpoon: no marks yet — <leader>ma to add the current file", vim.log.levels.INFO)
  end

  local items = {}
  for i, path in ipairs(marks) do
    items[i] = { idx = i, text = string.format("%d  %s", i, vim.fn.fnamemodify(path, ":~:.")) }
  end

  require("snacks").picker.pick({
    title = "Harpoon",
    items = items,
    format = "text",
    confirm = function(picker, item)
      picker:close()
      if item then M.jump(item.idx) end
    end,
    win = {
      input = {
        keys = { ["<c-x>"] = { "harpoon_remove", mode = { "n", "i" } } },
      },
    },
    actions = {
      harpoon_remove = function(picker, item)
        if not item then return end
        table.remove(marks, item.idx)
        save(marks)
        vim.notify("harpoon: removed mark " .. item.idx, vim.log.levels.INFO)
        picker:close()
        M.list()
      end,
    },
  })
end

return M
