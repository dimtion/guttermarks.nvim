local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local helpers = dofile("test/helpers.lua")

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
      child.lua([[M = require('guttermarks')]])
    end,
    post_once = child.stop,
  },
})

T["Disabled by default"] = function()
  new_buf()
  child.type_keys({ "gg", "vj", "<esc>" })

  local gutter = helpers.get_gutter(child)
  local has_special = false
  for _, mark in ipairs(gutter) do
    if mark[4]["sign_text"]:match("[<>]") then
      has_special = true
      break
    end
  end
  eq(has_special, false)
end

T["Enable special marks in config"] = function()
  child.lua([[M.setup({ special_mark = { enabled = true } })]])
  new_buf()
  child.type_keys({ "gg", "vj", "<esc>", "gg" })

  local gutter = helpers.get_gutter(child)
  local has_special = false
  for _, mark in ipairs(gutter) do
    local sign = mark[4]["sign_text"]
    if sign:match("[<>]") then
      has_special = true
      break
    end
  end
  eq(has_special, true)
end

T["Visual selection marks"] = function()
  child.lua([[M.setup({ special_mark = { enabled = true } })]])
  new_buf()
  child.type_keys({ "gg", "vjj", "<esc>", "gg" })

  local gutter = helpers.get_gutter(child)
  local has_lt = false
  local has_gt = false

  for _, mark in ipairs(gutter) do
    local sign = mark[4]["sign_text"]:gsub("%s", "")
    if sign == "<" then
      has_lt = true
    end
    if sign == ">" then
      has_gt = true
    end
  end

  eq(has_lt, true)
  eq(has_gt, true)
end

T["Change mark"] = function()
  child.lua([[M.setup({ special_mark = { enabled = true } })]])
  new_buf()
  child.type_keys({ "gg", "ix", "<esc>" })

  local gutter = helpers.get_gutter(child)
  local has_change = false

  for _, mark in ipairs(gutter) do
    local sign = mark[4]["sign_text"]:gsub("%s", "")
    if sign == "." then
      has_change = true
      break
    end
  end

  eq(has_change, true)
end

T["Custom sign for special marks"] = function()
  child.lua([[M.setup({ special_mark = { enabled = true, sign = "●" } })]])
  new_buf()
  child.type_keys({ "gg", "vj", "<esc>", "gg" })

  local gutter = helpers.get_gutter(child)
  local has_custom = false

  for _, mark in ipairs(gutter) do
    local sign = mark[4]["sign_text"]:gsub("%s", "")
    if sign == "●" then
      has_custom = true
      break
    end
  end

  eq(has_custom, true)
end

return T
