-- Performance benchmarks for guttermarks navigation operations
local bench_helpers = dofile("test/bench/helpers_bench.lua")
local child = MiniTest.new_child_neovim()

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      child.restart({ "-u", "test/bench/init.lua" })
      child.lua([[
        require("guttermarks").setup()
      ]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

-- Benchmark: next_buf_mark with varying mark counts
T["next_buf_mark with 1 mark"] = function()
  bench_helpers.setup_local_marks(child, 1, 100)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - 1 mark", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["next_buf_mark with 5 marks"] = function()
  bench_helpers.setup_local_marks(child, 5, 100)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - 5 marks", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["next_buf_mark with 10 marks"] = function()
  bench_helpers.setup_local_marks(child, 10, 200)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - 10 marks", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["next_buf_mark with 26 marks"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - 26 marks", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: prev_buf_mark with varying mark counts
T["prev_buf_mark with 5 marks"] = function()
  bench_helpers.setup_local_marks(child, 5, 100)
  child.api.nvim_win_set_cursor(0, { 100, 0 })

  local results = bench_helpers.benchmark("prev_buf_mark() - 5 marks", function()
    child.lua([[require("guttermarks.actions").prev_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["prev_buf_mark with 26 marks"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  child.api.nvim_win_set_cursor(0, { 500, 0 })

  local results = bench_helpers.benchmark("prev_buf_mark() - 26 marks", function()
    child.lua([[require("guttermarks.actions").prev_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Worst-case scenarios for navigation
T["next_buf_mark worst case (last mark)"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  -- Position cursor just before the last mark to test worst-case
  child.api.nvim_win_set_cursor(0, { 480, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - worst case (near last mark)", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["prev_buf_mark worst case (first mark)"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  -- Position cursor just after the first mark to test worst-case
  child.api.nvim_win_set_cursor(0, { 30, 0 })

  local results = bench_helpers.benchmark("prev_buf_mark() - worst case (near first mark)", function()
    child.lua([[require("guttermarks.actions").prev_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Navigation with mixed marks
T["next_buf_mark with mixed marks"] = function()
  bench_helpers.setup_mixed_marks(child, 10, 5, 500)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - mixed marks (10 local + 5 global)", function()
    child.lua([[require("guttermarks.actions").next_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["prev_buf_mark with mixed marks"] = function()
  bench_helpers.setup_mixed_marks(child, 10, 5, 500)
  child.api.nvim_win_set_cursor(0, { 500, 0 })

  local results = bench_helpers.benchmark("prev_buf_mark() - mixed marks (10 local + 5 global)", function()
    child.lua([[require("guttermarks.actions").prev_buf_mark()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Consecutive navigation calls
T["consecutive next_buf_mark calls"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  child.api.nvim_win_set_cursor(0, { 1, 0 })

  local results = bench_helpers.benchmark("next_buf_mark() - 10 consecutive calls", function()
    for _ = 1, 10 do
      child.lua([[require("guttermarks.actions").next_buf_mark()]])
    end
  end, 50)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["consecutive prev_buf_mark calls"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  child.api.nvim_win_set_cursor(0, { 500, 0 })

  local results = bench_helpers.benchmark("prev_buf_mark() - 10 consecutive calls", function()
    for _ = 1, 10 do
      child.lua([[require("guttermarks.actions").prev_buf_mark()]])
    end
  end, 50)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: marks_to_quickfix with varying mark counts
T["marks_to_quickfix with 5 marks"] = function()
  bench_helpers.setup_local_marks(child, 5, 100)

  local results = bench_helpers.benchmark("marks_to_quickfix() - 5 marks", function()
    child.lua([[require("guttermarks.actions").marks_to_quickfix()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["marks_to_quickfix with 26 marks"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)

  local results = bench_helpers.benchmark("marks_to_quickfix() - 26 marks", function()
    child.lua([[require("guttermarks.actions").marks_to_quickfix()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["marks_to_quickfix with mixed marks"] = function()
  bench_helpers.setup_mixed_marks(child, 26, 26, 1000)

  local results = bench_helpers.benchmark("marks_to_quickfix() - 52 marks (26 local + 26 global)", function()
    child.lua([[require("guttermarks.actions").marks_to_quickfix()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: delete_mark operation
T["delete_mark with 10 marks"] = function()
  bench_helpers.setup_local_marks(child, 10, 100)

  local results = bench_helpers.benchmark("delete_mark() - 10 marks present", function()
    -- Position cursor on a mark and delete it
    child.api.nvim_win_set_cursor(0, { 10, 0 })
    child.lua([[require("guttermarks.actions").delete_mark()]])
    -- Restore the mark for next iteration
    child.api.nvim_win_set_cursor(0, { 10, 0 })
    child.cmd("normal! ma")
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["delete_mark with 26 marks"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)

  local results = bench_helpers.benchmark("delete_mark() - 26 marks present", function()
    -- Position cursor on a mark and delete it
    child.api.nvim_win_set_cursor(0, { 20, 0 })
    child.lua([[require("guttermarks.actions").delete_mark()]])
    -- Restore the mark for next iteration
    child.api.nvim_win_set_cursor(0, { 20, 0 })
    child.cmd("normal! ma")
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

return T
