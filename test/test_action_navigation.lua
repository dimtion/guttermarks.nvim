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
  -- marks on lines 2 and 3; cursor starts at line 1 so no same-line ambiguity
  child.type_keys({ "gg", "0", "j", "0", "llll", "ma", "j", "0", "l", "mb", "gg", "0" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 4 })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
end

T["next_buf_mark"]["no marks ahead"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j" })

  child.lua([[ M.next_buf_mark({ wrap = false }) ]])
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
  -- marks on lines 2-4; cursor starts at line 1 so no same-line ambiguity
  child.type_keys({ "gg", "0", "j", "0", "lll", "ma", "j", "0", "mC", "j", "0", "l", "mb", "gg", "0" })

  child.lua([[ M.next_buf_mark({ global_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })

  child.lua([[ M.next_buf_mark({ global_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 4, 1 })
end

T["prev_buf_mark"]["navigates backward"] = function()
  new_buf()
  child.type_keys({ "gg", "ll", "ma", "j", "0", "llll", "mb", "j", "0", "l", "mc", "G" })

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })

  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 4 })
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
  child.type_keys({ "gg", "ll", "ma", "jj", "0", "lll", "mB", "jj", "0", "l", "mc", "G" })

  child.lua([[ M.prev_buf_mark({ local_mark = false }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 3, 3 })
end

T["Multiple marks on the same line"] = function()
  new_buf()
  -- mark a at line 2 col 1, mark b at line 2 col 3
  child.type_keys({ "gg", "0", "j", "0", "l", "ma", "ll", "mb", "gg", "0" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })

  -- navigate backward through same-line marks
  child.lua([[ M.prev_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 1 })
end

T["Mixed local and global marks"] = function()
  new_buf()
  -- mark a at cursor start position so it is not "ahead"; B and c are on later lines
  child.type_keys({ "gg", "0", "ma", "j", "0", "lll", "mB", "j", "0", "l", "mc", "gg", "0" })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })

  child.lua([[ M.next_buf_mark() ]])
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
end

T["next_buf_mark wrap"] = MiniTest.new_set()
T["prev_buf_mark wrap"] = MiniTest.new_set()

T["next_buf_mark wrap"]["wraps from last mark to first"] = function()
  new_buf()
  child.type_keys({ "gg", "0", "ll", "ma", "j", "0", "mb", "j", "0", "mc", "jj" })

  child.lua([[ M.next_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 1, 2 })
end

T["next_buf_mark wrap"]["does not wrap when mark found ahead"] = function()
  new_buf()
  -- mark a at col 0, cursor ends at col 3 after gg (preserved), so a is behind
  child.type_keys({ "gg", "0", "ma", "j", "0", "lll", "mb", "gg" })

  child.lua([[ M.next_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })
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

  child.lua([[ M.next_buf_mark({ wrap = false }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 5)
end

T["prev_buf_mark wrap"]["wraps from first mark to last"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "0", "mb", "j", "0", "l", "mc", "gg" })

  child.lua([[ M.prev_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 3, 1 })
end

T["prev_buf_mark wrap"]["does not wrap when mark found behind"] = function()
  new_buf()
  child.type_keys({ "gg", "ma", "j", "0", "lll", "mb", "G" })

  child.lua([[ M.prev_buf_mark({ wrap = true }) ]])
  eq(child.api.nvim_win_get_cursor(0), { 2, 3 })
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

  child.lua([[ M.prev_buf_mark({ wrap = false }) ]])
  eq(child.api.nvim_win_get_cursor(0)[1], 1)
end

return T
