local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local helpers = dofile("test/helpers.lua")

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iline1<cr>line2<cr>line3<esc>gg")
end

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

T["Custom sign as string"] = function()
  child.lua([[M.setup({ local_mark = { sign = "▶" } })]])
  new_buf()
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"]:match("▶"), "▶")
end

T["Custom sign as function"] = function()
  child.lua([[M.setup({
    local_mark = {
      sign = function(mark)
        return mark.mark:upper()
      end
    }
  })]])
  new_buf()
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"]:match("A"), "A")
end

T["Excluded filetypes"] = function()
  child.lua([[M.setup({ excluded_filetypes = { "json" } })]])
  new_buf()
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 0)
end

T["Excluded buftypes"] = function()
  child.lua([[M.setup({ excluded_buftypes = { "nofile" } })]])
  child.bo.buftype = "nofile"
  child.bo.ft = "json"
  child.type_keys("iline1<cr>line2<esc>gg")
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 0)
end

T["Disable local marks"] = function()
  child.lua([[M.setup({ local_mark = { enabled = false } })]])
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"]:match("B"), "B")
end

T["Disable global marks"] = function()
  child.lua([[M.setup({ global_mark = { enabled = false } })]])
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"]:match("a"), "a")
end

T["Custom highlight group"] = function()
  child.lua([[M.setup({ local_mark = { highlight_group = "CustomHL" } })]])
  new_buf()
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_hl_group"], "CustomHL")
end

T["Custom priority"] = function()
  child.lua([[M.setup({ local_mark = { priority = 99 } })]])
  new_buf()
  child.type_keys({ "gg", "ma" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["priority"], 99)
end

T["Different signs for different mark types"] = function()
  child.lua([[M.setup({
    local_mark = { sign = "●" },
    global_mark = { sign = "◆" }
  })]])
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 2)

  local has_local = false
  local has_global = false

  for _, mark in ipairs(gutter) do
    local sign = mark[4]["sign_text"]:gsub("%s", "")
    if sign == "●" then
      has_local = true
    end
    if sign == "◆" then
      has_global = true
    end
  end

  eq(has_local, true)
  eq(has_global, true)
end

return T
