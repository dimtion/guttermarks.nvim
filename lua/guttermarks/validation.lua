local M = {}

--- Validates that a value is a positive integer
---@param value any
---@return boolean
local function is_positive_integer(value)
  return type(value) == "number" and value > 0 and math.floor(value) == value
end

--- Validates that a value is a non-empty string
---@param value any
---@return boolean
local function is_non_empty_string(value)
  return type(value) == "string" and value ~= ""
end

--- Validates a mark configuration (local_mark, global_mark, or special_mark)
---@param mark_config table
---@param mark_type string
local function validate_mark_config(mark_config, mark_type)
  if mark_config.enabled ~= nil then
    vim.validate({
      [mark_type .. ".enabled"] = { mark_config.enabled, "boolean" },
    })
  end

  if mark_config.sign ~= nil then
    vim.validate({
      [mark_type .. ".sign"] = {
        mark_config.sign,
        function(v)
          if type(v) == "string" then
            return is_non_empty_string(v)
          elseif type(v) == "function" then
            return true
          end
          return false
        end,
        "string or function (non-empty)",
      },
    })
  end

  if mark_config.highlight_group ~= nil then
    vim.validate({
      [mark_type .. ".highlight_group"] = { mark_config.highlight_group, "string" },
    })
  end

  if mark_config.priority ~= nil then
    vim.validate({
      [mark_type .. ".priority"] = {
        mark_config.priority,
        is_positive_integer,
        "positive integer",
      },
    })
  end

  if mark_type == "special_mark" and mark_config.marks ~= nil then
    vim.validate({
      ["special_mark.marks"] = { mark_config.marks, "table" },
    })
  end
end

--- Validates the configuration passed to setup()
---@param opts table
M.validate_config = function(opts)
  vim.validate({
    opts = { opts, "table" },
  })

  if opts.local_mark ~= nil then
    vim.validate({
      local_mark = { opts.local_mark, "table" },
    })
    validate_mark_config(opts.local_mark, "local_mark")
  end

  if opts.global_mark ~= nil then
    vim.validate({
      global_mark = { opts.global_mark, "table" },
    })
    validate_mark_config(opts.global_mark, "global_mark")
  end

  if opts.special_mark ~= nil then
    vim.validate({
      special_mark = { opts.special_mark, "table" },
    })
    validate_mark_config(opts.special_mark, "special_mark")
  end

  if opts.autocmd_triggers ~= nil then
    vim.validate({
      autocmd_triggers = { opts.autocmd_triggers, "table" },
    })
    if #opts.autocmd_triggers == 0 then
      error("autocmd_triggers cannot be empty (plugin won't refresh)")
    end
  end

  if opts.excluded_filetypes ~= nil then
    vim.validate({
      excluded_filetypes = { opts.excluded_filetypes, "table" },
    })
  end

  if opts.excluded_buftypes ~= nil then
    vim.validate({
      excluded_buftypes = { opts.excluded_buftypes, "table" },
    })
  end
end

return M
