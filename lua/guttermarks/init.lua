--- guttermarks.nvim
--- A simple Neovim plugin to display marks in the buffer gutter

---@class guttermarks.Mark
---@field mark string
---@field line number
---@field type "local_mark"|"global_mark"|"special_mark"

local M = {}

---@type number
M.ns_id = nil

---@type boolean
M.is_enabled = false

---@type guttermarks.Config
M.config = nil

---Setup the plugin configuration.
---Overrides the default configuration with the provided config passed as a parameter
---@param opts? guttermarks.Config
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", require("guttermarks.config"), opts)
end

---Configure initial hooks to use the plugin. Call this function once
function M.init()
  if M.config == nil then
    M.setup()
  end

  M.ns_id = vim.api.nvim_create_namespace("gutter_marks")
  M.is_enabled = true

  vim.api.nvim_set_hl(0, M.config.local_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.global_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.special_mark.highlight_group, { default = true })

  local group = vim.api.nvim_create_augroup("GutterMarks", { clear = true })

  vim.api.nvim_create_autocmd(M.config.autocmd_triggers, {
    group = group,
    callback = function()
      vim.schedule(M.refresh)
    end,
  })

  vim.api.nvim_create_autocmd("CmdlineLeave", {
    group = group,
    callback = function()
      vim.schedule(function()
        local cmdline = vim.fn.histget("cmd", -1)
        if cmdline:match("^m[a-zA-Z0-9]") or cmdline:match("^delm") then
          M.refresh()
        end
      end)
    end,
    desc = "Refresh GutterMarks on CmdlineLeave",
  })

  vim.api.nvim_create_autocmd("ModeChanged", {
    group = group,
    pattern = "[vV\x16]:*",
    callback = function()
      M.refresh()
    end,
    desc = "Refresh GutterMarks on visual ModeChange",
  })

  M.excluded_filetypes = {}
  for _, ft in ipairs(M.config.excluded_filetypes) do
    M.excluded_filetypes[ft] = true
  end

  M.excluded_buftypes = {}
  for _, ft in ipairs(M.config.excluded_buftypes) do
    M.excluded_buftypes[ft] = true
  end

  vim.keymap.set("n", "m", function()
    local char = vim.fn.getchar()
    local key = vim.fn.nr2char(char)
    vim.api.nvim_feedkeys("m" .. key, "n", true)
    vim.schedule(M.refresh)
  end, { desc = "Set mark (with gutter update)" })
end

---Returns the list of enabled and valid marks in the selected buffer
---@param bufnr number Buffer number
---@return guttermarks.Mark[]
local function get_buffer_marks(bufnr)
  local utils = require("guttermarks.utils")
  local marks = {}

  if M.config.local_mark.enabled then
    for _, mark in ipairs(vim.fn.getmarklist("%")) do
      local m = mark.mark:sub(2, 3)
      if utils.is_letter(m) and utils.is_valid_mark(bufnr, mark.pos[2]) then
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
      if mark.pos[1] == bufnr and utils.is_letter(m) and utils.is_valid_mark(bufnr, mark.pos[2]) then
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
      local pos = vim.api.nvim_buf_get_mark(bufnr, mark)
      if utils.is_valid_mark(bufnr, pos[1]) then
        table.insert(marks, {
          mark = mark,
          line = pos[1],
          type = "special_mark",
        })
      end
    end
  end

  return marks
end

---Refresh marks in current buffer
function M.refresh()
  if not M.is_enabled then
    return
  end

  local bufnr = vim.api.nvim_get_current_buf()

  if M.excluded_buftypes[vim.bo.bt] or M.excluded_filetypes[vim.bo.ft] then
    return
  end

  vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)

  local marks = get_buffer_marks(bufnr)

  for _, mark in ipairs(marks) do
    local sign_config = M.config[mark.type].sign
    local sign_text

    if type(sign_config) == "function" then
      sign_text = sign_config(mark)
    else
      sign_text = sign_config or mark.mark
    end

    vim.api.nvim_buf_set_extmark(bufnr, M.ns_id, mark.line - 1, 0, {
      sign_text = sign_text,
      sign_hl_group = M.config[mark.type].highlight_group,
      priority = M.config[mark.type].priority,
    })
  end
end

---Enable or disable guttermarks
---@param is_enabled boolean whether to enable or disable guttermarks
function M.enable(is_enabled)
  M.is_enabled = is_enabled
  if M.is_enabled then
    M.refresh()
  else
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M.ns_id, 0, -1)
  end
end

---Enable guttermarks if disable, disable guttermarks if enabled
function M.toggle()
  M.enable(not M.is_enabled)
end

return M
