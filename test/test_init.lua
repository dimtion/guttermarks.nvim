-- Basic test to verify the extension loads correctly

local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality
local neq = MiniTest.expect.no_equality

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iab<cr>cd<cr>ef<esc>gg")
end

local get_gutter = function()
  local ns = child.api.nvim_get_namespaces()["gutter_marks"]
  local bufnr = child.api.nvim_get_current_buf()
  neq(ns, nil)
  neq(bufnr, nil)
  local gutter = child.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {
    details = true,
  })
  return gutter
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

T["Extension loads"] = function()
  local ok, guttermarks = pcall(require, "guttermarks")
  eq(ok, true)
  eq(type(guttermarks.setup), "function")
  eq(type(guttermarks.init), "function")

  eq(child.lua_get([[ M.is_enabled ]]), true)
end

T["Simple mark"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys("ma")

  local gutter = get_gutter()
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"], "a ")
end

T["Delete mark"] = function()
  new_buf()
  child.type_keys("ma")
  child.type_keys(":delmarks a<cr>")

  eq(#get_gutter(), 0)
end

T["Multiple marks"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys({ "ma", "j", "mb" })

  local gutter = get_gutter()
  eq(#gutter, 2)
  eq(gutter[1][4]["sign_text"], "a ")
  eq(gutter[2][4]["sign_text"], "b ")
end

T["Complex flow"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys({ "ma", "j", "mb", ":delmarks a<cr>", "k", "mC" })

  local gutter = get_gutter()
  eq(#gutter, 2)
  eq(gutter[1][4]["sign_text"], "C ")
  eq(gutter[2][4]["sign_text"], "b ")
end

T["GutterMarks disabled"] = function()
  new_buf()
  child.lua([[ M.enable(false) ]])
  child.type_keys("ggj0")
  child.type_keys({ "ma" })

  local gutter = get_gutter()
  eq(#gutter, 0)
end

return T
