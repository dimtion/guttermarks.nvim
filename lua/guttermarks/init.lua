--- guttermarks.nvim
--- A simple Neovim plugin to display marks in the buffer gutter

---@class guttermarks.Mark
---@field mark string
---@field line number
---@field type "local_mark"|"global_mark"|"special_mark"

local M = {}

---GutterMarks namespace id
---@type number
M._ns = nil

---GutterMarks autogroup id
---@type number
M._au = nil

---is GutterMarks currently enabled
---@type boolean
M.is_enabled = false

---GutterMarks active configuration
---@type guttermarks.Config
M.config = nil

---Configure initial hooks to use the plugin.
---Call this function once or when the configuration changes
---Overrides the default configuration with the provided config passed as a parameter
---@param opts? guttermarks.Config
function M.setup(opts)
  opts = opts or {}
  M.config = vim.tbl_deep_extend("force", require("guttermarks.config"), opts)

  M._ns = vim.api.nvim_create_namespace("gutter_marks")
  M._au = vim.api.nvim_create_augroup("GutterMarks", { clear = true })
  M.is_enabled = true

  vim.api.nvim_set_hl(0, M.config.local_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.global_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.special_mark.highlight_group, { default = true })

  vim.api.nvim_create_autocmd(M.config.autocmd_triggers, {
    group = M._au,
    callback = function()
      vim.schedule(M.refresh)
    end,
  })

  if M.config.local_mark.enabled or M.config.global_mark.enabled then
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      group = M._au,
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

    vim.keymap.set("n", "m", function()
      local char = vim.fn.getchar()
      local key = vim.fn.nr2char(char)
      vim.api.nvim_feedkeys("m" .. key, "n", true)
      vim.schedule(M.refresh)
    end, { desc = "Set mark (with gutter update)" })
  end

  if M.config.special_mark.enabled then
    vim.api.nvim_create_autocmd("ModeChanged", {
      group = M._au,
      pattern = "[vV\x16]:*",
      callback = function()
        M.refresh()
      end,
      desc = "Refresh GutterMarks on visual ModeChange",
    })
  end

  M.excluded_filetypes = {}
  for _, ft in ipairs(M.config.excluded_filetypes) do
    M.excluded_filetypes[ft] = true
  end

  M.excluded_buftypes = {}
  for _, ft in ipairs(M.config.excluded_buftypes) do
    M.excluded_buftypes[ft] = true
  end
end

---Refresh marks in current buffer
---@return boolean false if nothing done
function M.refresh()
  if not M.is_enabled then
    return false
  end

  if M.excluded_buftypes[vim.bo.bt] or M.excluded_filetypes[vim.bo.ft] then
    return false
  end

  local bufnr = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)

  local marks = require("guttermarks.utils").get_buffer_marks(bufnr, M.config)

  for _, mark in ipairs(marks) do
    local sign_config = M.config[mark.type].sign
    local sign_text

    if type(sign_config) == "function" then
      sign_text = sign_config(mark)
    else
      sign_text = sign_config or mark.mark
    end

    vim.api.nvim_buf_set_extmark(bufnr, M._ns, mark.line - 1, 0, {
      sign_text = sign_text,
      sign_hl_group = M.config[mark.type].highlight_group,
      priority = M.config[mark.type].priority,
    })
  end

  return true
end

---Enable or disable guttermarks
---@param is_enabled boolean whether to enable or disable guttermarks
function M.enable(is_enabled)
  M.is_enabled = is_enabled
  if M.is_enabled then
    M.refresh()
  else
    local bufnr = vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_clear_namespace(bufnr, M._ns, 0, -1)
  end
end

---Enable guttermarks if disable, disable guttermarks if enabled
---@return boolean whether GutterMarks is enabled or disabled
function M.toggle()
  M.enable(not M.is_enabled)
  return M.is_enabled
end

return M
