local MiniTest = require("mini.test")
local T = MiniTest.new_set()

T["no deprecation warnings with complex config"] = function()
  local issues = {}

  vim.deprecate = function(name)
    table.insert(issues, "DEPRECATED: " .. name)
  end
  vim.health.warn = function(msg)
    table.insert(issues, "WARNING: " .. msg)
  end
  vim.health.error = function(msg)
    table.insert(issues, "ERROR: " .. msg)
  end

  require("guttermarks").setup({
    local_mark = {
      enabled = true,
      sign = function(mark)
        return mark.mark:upper()
      end,
      highlight_group = "GutterMarksLocal",
      priority = 20,
    },
    global_mark = {
      enabled = true,
      sign = ">>",
      highlight_group = "GutterMarksGlobal",
      priority = 21,
    },
    special_mark = {
      enabled = true,
      marks = { "'", "^", "." },
      sign = function(mark)
        return "[" .. mark.mark .. "]"
      end,
      highlight_group = "GutterMarksSpecial",
      priority = 15,
    },
    autocmd_triggers = { "BufEnter", "TextChanged" },
    excluded_filetypes = { "NvimTree", "TelescopePrompt", "" },
    excluded_buftypes = { "terminal", "prompt", "quickfix", "nofile" },
  })

  MiniTest.expect.equality(issues, {})
end

return T
