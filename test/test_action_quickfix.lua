local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iline1<cr>line2<cr>line3<cr>line4<esc>gg")
end

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      child.restart({ "-u", "test/init.lua" })
      child.bo.readonly = false
      child.lua([[M = require('guttermarks.actions')]])
    end,
    post_once = child.stop,
  },
})

T["Default behavior (local + global)"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB", "j", "mc" })

  child.lua([[ M.marks_to_quickfix() ]])

  local qf = child.fn.getqflist()
  eq(#qf, 3)

  local texts = {}
  for _, item in ipairs(qf) do
    table.insert(texts, item.text)
  end
  table.sort(texts)

  eq(texts[1], "Mark B (Global)")
  eq(texts[2], "Mark a (Local)")
  eq(texts[3], "Mark c (Local)")
end

T["Only local marks"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB", "j", "mc" })

  child.lua([[ M.marks_to_quickfix({ global_mark = false }) ]])

  local qf = child.fn.getqflist()
  eq(#qf, 2)
  eq(qf[1].text:match("Local"), "Local")
  eq(qf[2].text:match("Local"), "Local")
end

T["Only global marks"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB", "j", "mc" })

  child.lua([[ M.marks_to_quickfix({ local_mark = false }) ]])

  local qf = child.fn.getqflist()
  eq(#qf, 1)
  eq(qf[1].text:match("Global"), "Global")
end

T["No marks present"] = function()
  new_buf()

  child.lua([[ M.marks_to_quickfix() ]])

  local qf = child.fn.getqflist()
  eq(#qf, 0)
end

T["Quickfix list structure"] = function()
  new_buf()
  child.type_keys({ "gg", "ma" })

  child.lua([[ M.marks_to_quickfix() ]])

  local qf = child.fn.getqflist()
  eq(#qf, 1)
  eq(qf[1].lnum, 1)
  eq(type(qf[1].bufnr), "number")
  eq(type(qf[1].text), "string")
end

T["With special marks enabled"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "jvk", "<esc>", "gg" })

  child.lua([[ M.marks_to_quickfix({ special_mark = true }) ]])

  local qf = child.fn.getqflist()
  eq(#qf >= 1, true)

  local has_local = false
  for _, item in ipairs(qf) do
    if item.text:match("Local") then
      has_local = true
      break
    end
  end
  eq(has_local, true)
end

return T
