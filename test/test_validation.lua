local MiniTest = require("mini.test")
local error_matches = MiniTest.expect.error

local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "test/init.lua" })
      child.bo.readonly = false
      child.lua([[M = require('guttermarks')]])
    end,
    post_once = child.stop,
  },
})

-- Type Validations
T["Type validations"] = MiniTest.new_set()

T["Type validations"]["opts must be table or nil"] = function()
  error_matches(function()
    child.lua([[M.setup(123)]])
  end, "opts")
end

T["Type validations"]["opts string rejected"] = function()
  error_matches(function()
    child.lua([[M.setup("invalid")]])
  end, "opts")
end

T["Type validations"]["enabled must be boolean"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { enabled = "true" } })]])
  end, "enabled")
end

T["Type validations"]["enabled number rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { enabled = 1 } })]])
  end, "enabled")
end

T["Type validations"]["sign must be string or function"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { sign = 123 } })]])
  end, "sign")
end

T["Type validations"]["sign boolean rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { sign = true } })]])
  end, "sign")
end

T["Type validations"]["sign table rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { sign = {} } })]])
  end, "sign")
end

T["Type validations"]["highlight_group must be string"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { highlight_group = 123 } })]])
  end, "highlight_group")
end

T["Type validations"]["highlight_group function rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { highlight_group = function() end } })]])
  end, "highlight_group")
end

T["Type validations"]["priority must be number"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { priority = "10" } })]])
  end, "priority")
end

T["Type validations"]["priority boolean rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { priority = true } })]])
  end, "priority")
end

T["Type validations"]["autocmd_triggers must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ autocmd_triggers = "BufEnter" })]])
  end, "autocmd_triggers")
end

T["Type validations"]["autocmd_triggers number rejected"] = function()
  error_matches(function()
    child.lua([[M.setup({ autocmd_triggers = 123 })]])
  end, "autocmd_triggers")
end

T["Type validations"]["excluded_filetypes must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ excluded_filetypes = "json" })]])
  end, "excluded_filetypes")
end

T["Type validations"]["excluded_buftypes must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ excluded_buftypes = "terminal" })]])
  end, "excluded_buftypes")
end

T["Type validations"]["special_mark.marks must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ special_mark = { marks = "abc" } })]])
  end, "marks")
end

-- Value Validations
T["Value validations"] = MiniTest.new_set()

T["Value validations"]["priority must be positive"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { priority = -1 } })]])
  end, "priority")
end

T["Value validations"]["priority cannot be zero"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { priority = 0 } })]])
  end, "priority")
end

T["Value validations"]["priority must be integer"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { priority = 3.14 } })]])
  end, "priority")
end

T["Value validations"]["sign cannot be empty string"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = { sign = "" } })]])
  end, "sign")
end

T["Value validations"]["autocmd_triggers cannot be empty"] = function()
  error_matches(function()
    child.lua([[M.setup({ autocmd_triggers = {} })]])
  end, "autocmd_triggers")
end

-- Structure Validations
T["Structure validations"] = MiniTest.new_set()

T["Structure validations"]["local_mark must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ local_mark = "enabled" })]])
  end, "local_mark")
end

T["Structure validations"]["global_mark must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ global_mark = 123 })]])
  end, "global_mark")
end

T["Structure validations"]["special_mark must be table"] = function()
  error_matches(function()
    child.lua([[M.setup({ special_mark = true })]])
  end, "special_mark")
end

return T
