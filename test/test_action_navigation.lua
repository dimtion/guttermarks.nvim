local MiniTest = require("mini.test")
local eq = MiniTest.expect.equality

local child = MiniTest.new_child_neovim()

local new_buf = function()
  child.bo.ft = "json"
  child.type_keys("iline1<cr>line2<cr>line3<cr>line4<cr>line5<esc>gg")
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

T["next_buf_mark"] = MiniTest.new_set()
T["prev_buf_mark"] = MiniTest.new_set()

T["next_buf_mark"]["navigates forward"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "j", "mc", "gg" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 3)
end

T["next_buf_mark"]["no marks ahead"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)
end

T["next_buf_mark"]["no marks present"] = function()
  new_buf()
  local start_line = child.api.nvim_win_get_cursor(0)[1]

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], start_line)
end

T["next_buf_mark"]["skips global marks with opts"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "j", "mC", "j", "md", "gg" })

  child.lua([[ M.next_buf_mark({ global_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)

  child.lua([[ M.next_buf_mark({ global_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 4)
end

T["prev_buf_mark"]["navigates backward"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "j", "mc", "G" })

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 3)

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)
end

T["prev_buf_mark"]["no marks behind"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "gg" })

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 1)
end

T["prev_buf_mark"]["no marks present"] = function()
  new_buf()
  local start_line = child.api.nvim_win_get_cursor(0)[1]

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], start_line)
end

T["prev_buf_mark"]["skips local marks with opts"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "jj", "mB", "jj", "mc", "G" })

  child.lua([[ M.prev_buf_mark({ local_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 3)
end

T["Mixed local and global marks"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mB", "j", "mc", "gg" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 3)
end

T["next_buf_mark wrap"] = MiniTest.new_set()
T["prev_buf_mark wrap"] = MiniTest.new_set()

T["next_buf_mark wrap"]["wraps from last mark to first"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "j", "mc", "G" })

  child.lua([[ M.next_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 1)
end

T["next_buf_mark wrap"]["does not wrap when mark found ahead"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "gg" })

  child.lua([[ M.next_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)
end

T["next_buf_mark wrap"]["no marks present stays put"] = function()
  new_buf()
  local start_line = child.api.nvim_win_get_cursor(0)[1]

  child.lua([[ M.next_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], start_line)
end

T["next_buf_mark wrap"]["no wrap without opt"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "G" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 5)
end

T["prev_buf_mark wrap"]["wraps from first mark to last"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "j", "mc", "gg" })

  child.lua([[ M.prev_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 3)
end

T["prev_buf_mark wrap"]["does not wrap when mark found behind"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "G" })

  child.lua([[ M.prev_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 2)
end

T["prev_buf_mark wrap"]["no marks present stays put"] = function()
  new_buf()
  local start_line = child.api.nvim_win_get_cursor(0)[1]

  child.lua([[ M.prev_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], start_line)
end

T["prev_buf_mark wrap"]["no wrap without opt"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "mb", "gg" })

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 1)
end

return T
