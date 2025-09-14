-- guttermarks.nvim
-- A simple Neovim plugin to display marks in the buffer gutter

local M = {}

M.ns_id = nil
M.enabled = true
M.config = nil

---Setup the plugin configuration.
---Overrides the default configuration with the provided config passed as a parameter
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", require("guttermarks.config"), opts)
end

---Configure initial hooks to use the plugin. Call this function once
function M.init()
  if M.config == nil then
    M.setup()
  end

  M.ns_id = vim.api.nvim_create_namespace("marks_gutter")

  vim.api.nvim_set_hl(0, M.config.local_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.global_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.special_mark.highlight_group, { default = true })

  local group = vim.api.nvim_create_augroup("MarksGutter", { clear = true })

  vim.api.nvim_create_autocmd(M.config.autocmd_triggers, {
    group = group,
    callback = function()
      vim.schedule(M.refresh)
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      local cmdline = vim.fn.histget("cmd", -1)
      if cmdline:match("^m[a-zA-Z0-9]") or cmdline:match("^delm") then
        vim.schedule(M.refresh)
      end
    end,
  })

  M.excluded_filetypes = {}
  for _, ft in ipairs(M.config.excluded_filetypes) do
    M.excluded_filetypes[ft] = true
  end

  M.excluded_buftypes = {}
  for _, ft in ipairs(M.config.excluded_buftypes) do
    M.excluded_buftypes[ft] = true
  end

  M.setup_mark_hooks()
end

function M.setup_mark_hooks()
  vim.keymap.set("n", "m", function()
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    vim.api.nvim_feedkeys("m" .. key, "n", true)
    vim.schedule(M.refresh)
  end, { desc = "Set mark (with gutter update)" })
end

local function add_mark(marks, bufnr, mark, type)
  local pos = vim.api.nvim_buf_get_mark(bufnr, mark)
  if pos[1] <= 0 then -- Invalid mark (line <= 0)
    return
  end

  table.insert(marks, {
    mark = mark,
    line = pos[1],
    type = type,
  })
end

local function get_buffer_marks(bufnr)
  local utils = require("guttermarks.utils")
  local marks = {}

  if M.config.local_mark.enabled then
    for _, mark in ipairs(vim.fn.getmarklist("%")) do
      local m = mark.mark:sub(2, 3)
      if utils.is_letter(m) then
        table.insert(marks, {
          mark = m,
          line = mark.pos[2],
          type = "local_mark",
        })
      end
    end
  end

  if M.config.global_mark.enabled then
    for _, mark in ipairs(vim.fn.getmarklist()) do
      local m = mark.mark:sub(2, 3)
      if mark.pos[1] == bufnr and utils.is_letter(m) then
        table.insert(marks, {
          mark = m,
          line = mark.pos[2],
          type = "global_mark",
        })
      end
    end
  end

  if M.config.special_mark.enabled then
    for _, mark in ipairs(M.config.special_mark.marks) do
      add_mark(marks, bufnr, mark, "special_mark")
    end
  end

  return marks
end

---Refresh marks in current buffer
function M.refresh()
  if not M.enabled then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if M.excluded_buftypes[vim.bo.bt] or M.excluded_filetypes[vim.bo.ft] then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)

  local marks = get_buffer_marks(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)

  for _, mark in ipairs(marks) do
    local sign_config = M.config[mark.type].sign
    local sign_text

    if type(sign_config) == "function" then
      sign_text = sign_config(mark)
    else
      sign_text = sign_config or mark.mark
    end

    if mark.line >= 1 and mark.line <= line_count then
      vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, mark.line - 1, 0, {
        sign_text = sign_text,
        sign_hl_group = M.config[mark.type].highlight_group,
        priority = M.config[mark.type].priority,
      })
    end
  end
end

---Enable or disable guttermarks
---@param is_enabled boolean whether to enable or disable guttermarks
function M.enable(is_enabled)
  M.enabled = is_enabled
  if M.enabled then
    M.refresh()
  else
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
  end
end

---Enable guttermarks if disable, disable guttermarks if enabled
function M.toggle()
  M.enable(not M.enabled)
end

return M
