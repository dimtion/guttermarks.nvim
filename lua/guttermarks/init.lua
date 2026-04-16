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

---Cache of marks per buffer
---@type table<number, guttermarks.Mark[]>
M._marks_cache = {}

---Clear all signs and cache
function M._clear()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_clear_namespace(buf, M._ns, 0, -1)
    end
  end
  M._marks_cache = {}
end

---Configure initial hooks to use the plugin.
---Call this function once or when the configuration changes
---Overrides the default configuration with the provided config passed as a parameter
---@param opts? guttermarks.Config
function M.setup(opts)
  opts = opts or {}
  require("guttermarks.validation").validate_config(opts)
  M.config = vim.tbl_deep_extend("force", require("guttermarks.config"), opts)

  M._ns = vim.api.nvim_create_namespace("gutter_marks")
  M._clear()

  M._au = vim.api.nvim_create_augroup("GutterMarks", { clear = true })

  vim.api.nvim_set_hl(0, M.config.local_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.global_mark.highlight_group, { default = true })
  vim.api.nvim_set_hl(0, M.config.special_mark.highlight_group, { default = true })

  vim.api.nvim_create_autocmd(M.config.autocmd_triggers, {
    desc = "Refresh GutterMarks on config.autocmd_triggers",
    group = M._au,
    callback = function(o)
      vim.schedule(function()
        M._refresh_buf(o.buf)
      end)
    end,
  })

  vim.api.nvim_create_autocmd("BufDelete", {
    desc = "Clear GutterMarks cache on buffer delete",
    group = M._au,
    callback = function(ev)
      M._marks_cache[ev.buf] = nil
    end,
  })

  if M.config.local_mark.enabled or M.config.global_mark.enabled then
    -- Taking advantage of MarkSet new autocmd in Nvim 0.12 to reduce overrides
    -- Notes: It doesn't support delmarks and special marks yet
    local nvim012 = vim.fn.has("nvim-0.12") == 1
    vim.api.nvim_create_autocmd("CmdlineLeave", {
      desc = "Refresh GutterMarks on CmdlineLeave",
      group = M._au,
      callback = function()
        vim.schedule(function()
          local cmdline = vim.fn.histget("cmd", -1)
          if (not nvim012 and cmdline:match("^ma")) or cmdline:match("^delm") then
            -- For Global mark need to refresh all buffers since we don't know
            -- if the Global mark was set somewhere else (and where)
            M.refresh({ buf = -1 })
          end
        end)
      end,
    })
    if nvim012 then
      -- TODO: Investigate if incremental update (single mark) is worth the
      -- performance improvement
      vim.api.nvim_create_autocmd("MarkSet", {
        desc = "Refresh GutterMarks on MarkSet",
        group = M._au,
        callback = function(o)
          -- For Global mark need to refresh all buffers since we don't know
          -- if the Global mark was set somewhere else (and where)
          if require("guttermarks.utils").is_upper(o.data.name) then
            M.refresh({ buf = -1 })
          else
            M._refresh_buf(o.buf)
          end
        end,
      })
    else
      vim.keymap.set("n", "m", function()
        local char = vim.fn.getchar()
        local key = vim.fn.nr2char(char)
        vim.api.nvim_feedkeys("m" .. key, "n", true)

        if require("guttermarks.utils").is_upper(key) then
          vim.schedule(function()
            M.refresh({ buf = -1 })
          end)
        else
          vim.schedule(M.refresh)
        end
      end, { desc = "Set mark (with gutter update)" })
    end
  end

  if M.config.special_mark.enabled then
    vim.api.nvim_create_autocmd("ModeChanged", {
      desc = "Refresh GutterMarks on visual ModeChange",
      group = M._au,
      pattern = "[vV\x16]:*",
      callback = function(o)
        M._refresh_buf(o.buf)
      end,
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

  -- Default to enable when configuring plugin
  M.enable(true)
end

---Refresh marks
---@return boolean false if nothing done
function M.refresh(opts)
  opts = opts or { buf = 0 }
  if opts.buf == 0 then
    local buf = vim.api.nvim_get_current_buf()
    return M._refresh_buf(buf)
  end

  if opts.buf == -1 then
    local changed = false
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      changed = M._refresh_buf(buf) or changed
    end
    return changed
  end

  return M._refresh_buf(opts.buf)
end

---Refresh marks in single buffer
---@return boolean false if nothing done
function M._refresh_buf(buf)
  if not M.is_enabled then
    return false
  end

  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end

  if M.excluded_buftypes[vim.bo[buf].bt] or M.excluded_filetypes[vim.bo[buf].ft] then
    return false
  end

  local utils = require("guttermarks.utils")
  local marks = utils.get_buffer_marks(buf, M.config)

  local cached_marks = M._marks_cache[buf]
  if cached_marks and utils.marks_equal(marks, cached_marks) then
    return true
  end

  vim.api.nvim_buf_clear_namespace(buf, M._ns, 0, -1)

  for _, mark in ipairs(marks) do
    local sign_config = M.config[mark.type].sign
    local sign_text

    if type(sign_config) == "function" then
      sign_text = sign_config(mark)
    else
      sign_text = sign_config or mark.mark
    end

    vim.api.nvim_buf_set_extmark(buf, M._ns, mark.line - 1, 0, {
      sign_text = sign_text,
      sign_hl_group = M.config[mark.type].highlight_group,
      priority = M.config[mark.type].priority,
    })
  end

  M._marks_cache[buf] = marks

  return true
end

---Enable or disable guttermarks
---@param is_enabled boolean whether to enable or disable guttermarks
function M.enable(is_enabled)
  M.is_enabled = is_enabled
  if M.is_enabled then
    M.refresh({ buf = -1 })
  else
    M._clear()
  end
end

---Enable guttermarks if disable, disable guttermarks if enabled
---@return boolean whether GutterMarks is enabled or disabled
function M.toggle()
  M.enable(not M.is_enabled)
  return M.is_enabled
end

return M
