-- Basic test to verify the extension loads correctly

local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local helpers = dofile("test/helpers.lua")

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iab<cr>cd<cr>ef<esc>gg")
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

T["alphabet"] = MiniTest.new_set({
  parametrize = vim.tbl_extend("keep", helpers.alphabet_lower, helpers.alphabet_upper),
})

T["alphabet"]["Delete mark simple"] = function(x)
  new_buf()
  child.type_keys("ggj0")
  child.type_keys("m" .. x)

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"], x .. " ")

  child.lua([[  M.delete_mark() ]])

  gutter = helpers.get_gutter(child)
  eq(#gutter, 0)
end

T["alphabet"]["Delete mark wrong line"] = function(x)
  new_buf()
  child.type_keys("ggj0")
  child.type_keys("m" .. x)
  child.type_keys("j")
  child.lua([[  M.delete_mark() ]])

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"], x .. " ")
end

T["Delete mark multiple present"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 2)

  child.lua([[  M.delete_mark() ]])

  gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
end

return T
