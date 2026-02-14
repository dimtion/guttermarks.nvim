-- Basic test to verify the extension loads correctly

local MiniTest = require("mini.test")
local helpers = dofile("test/helpers.lua")
local eq = MiniTest.expect.equality

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
      child.lua([[M = require('guttermarks')]])
    end,
    post_once = child.stop,
  },
})

T["Extension loads"] = function()
  local ok, guttermarks = pcall(require, "guttermarks")
  eq(ok, true)
  eq(type(guttermarks.setup), "function")
  eq(type(guttermarks.refresh), "function")
  eq(type(guttermarks.enable), "function")
  eq(type(guttermarks.toggle), "function")

  eq(child.lua_get([[ M.is_enabled ]]), true)
end

T["Simple mark"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys("ma")

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"], "a ")
end

T["Delete mark"] = function()
  new_buf()
  child.type_keys("ma")
  child.type_keys(":delmarks a<cr>")

  eq(#helpers.get_gutter(child), 0)
end

T["Multiple marks"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys({ "ma", "j", "mb" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 2)
  eq(gutter[1][4]["sign_text"], "a ")
  eq(gutter[2][4]["sign_text"], "b ")
end

T["Complex flow"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys({ "ma", "j", "mb", ":delmarks a<cr>", "k", "mC" })

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 2)
  eq(gutter[1][4]["sign_text"], "C ")
  eq(gutter[2][4]["sign_text"], "b ")
end

T["enable()"] = function()
  new_buf()
  child.lua([[ M.enable(false) ]])
  child.type_keys("ggj0")
  child.type_keys({ "ma" })

  eq(#helpers.get_gutter(child), 0)

  child.lua([[ M.enable(true) ]])
  eq(#helpers.get_gutter(child), 1)
end

T["enable(false) clears signs in all loaded buffers"] = function()
  -- Set up buf1 with a mark and verify the sign appears
  new_buf()
  child.type_keys("ggj0")
  child.type_keys("ma")
  local buf1 = child.api.nvim_get_current_buf()
  local ns = child.api.nvim_get_namespaces()["gutter_marks"]
  local signs_buf1 = child.api.nvim_buf_get_extmarks(buf1, ns, 0, -1, { details = true })
  eq(#signs_buf1, 1)

  -- Switch to a new buffer and set a mark there (buf1 is no longer current)
  child.lua([[vim.cmd('enew')]])
  child.bo.ft = "json"
  child.type_keys("iab<cr>cd<cr>ef<esc>gg")
  child.type_keys("ggj0mb")

  -- Disable from the new buffer; buf1 is a non-current loaded buffer
  child.lua([[M.enable(false)]])

  -- Signs in buf1 must be cleared even though it was not the current buffer
  signs_buf1 = child.api.nvim_buf_get_extmarks(buf1, ns, 0, -1, { details = true })
  eq(#signs_buf1, 0)
end

T["toggle()"] = function()
  new_buf()
  child.lua([[ M.enable(false) ]])
  child.type_keys("ggj0")
  child.type_keys({ "ma" })

  eq(child.lua_get([[ M.toggle() ]]), true)
  eq(#helpers.get_gutter(child), 1)

  eq(child.lua_get([[ M.toggle() ]]), false)
  eq(#helpers.get_gutter(child), 0)
end

T["Mark set via :mark command triggers sign"] = function()
  new_buf()
  child.type_keys("ggj0")
  -- Set mark via ex command (not the 'm' keymap override), so only
  -- the CmdlineLeave autocmd can trigger the sign refresh.
  child.type_keys(":mark a<cr>")

  local gutter = helpers.get_gutter(child)
  eq(#gutter, 1)
  eq(gutter[1][4]["sign_text"], "a ")
end

T["(force) refresh()"] = function()
  new_buf()
  child.type_keys("ggj0")
  child.type_keys({ "ma" })

  local bufnr = child.api.nvim_get_current_buf()
  local ns = child.api.nvim_get_namespaces()["gutter_marks"]
  child.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  eq(#helpers.get_gutter(child), 0)

  child.lua([[M._marks_cache[vim.api.nvim_get_current_buf()] = nil]])
  eq(child.lua_get([[ M.refresh() ]]), true)
  eq(#helpers.get_gutter(child), 1)
end

T["m keymap removed on disable and restored on enable"] = function()
  new_buf()
  -- Keymap must be registered after setup
  eq(child.lua_get([[vim.fn.mapcheck("m", "n") ~= ""]]), true)

  child.lua("M.enable(false)")
  -- Keymap must be removed so users can define their own
  eq(child.lua_get([[vim.fn.mapcheck("m", "n")]]), "")

  child.lua("M.enable(true)")
  -- Keymap must be re-registered when re-enabled
  eq(child.lua_get([[vim.fn.mapcheck("m", "n") ~= ""]]), true)
end

return T
