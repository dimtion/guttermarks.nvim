-- Performance benchmarks for guttermarks refresh operations
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

-- Benchmark: Refresh with varying number of local marks
T["refresh with 1 local mark"] = function()
  bench_helpers.setup_local_marks(child, 1, 100)
  local results = bench_helpers.benchmark("refresh() with 1 local mark (100 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with 5 local marks"] = function()
  bench_helpers.setup_local_marks(child, 5, 100)
  local results = bench_helpers.benchmark("refresh() with 5 local marks (100 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with 10 local marks"] = function()
  bench_helpers.setup_local_marks(child, 10, 100)
  local results = bench_helpers.benchmark("refresh() with 10 local marks (100 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with 26 local marks"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  local results = bench_helpers.benchmark("refresh() with 26 local marks (500 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Refresh with mixed marks
T["refresh with mixed marks (light user)"] = function()
  bench_helpers.setup_mixed_marks(child, 3, 0, 500)
  local results = bench_helpers.benchmark("refresh() - light user (3 local, 0 global, 500 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with mixed marks (power user)"] = function()
  bench_helpers.setup_mixed_marks(child, 10, 5, 1000)
  local results = bench_helpers.benchmark("refresh() - power user (10 local, 5 global, 1000 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with mixed marks (edge case)"] = function()
  bench_helpers.setup_mixed_marks(child, 26, 26, 5000)
  local results = bench_helpers.benchmark("refresh() - edge case (26 local, 26 global, 5000 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Refresh with different buffer sizes
T["refresh small buffer"] = function()
  bench_helpers.setup_local_marks(child, 5, 100)
  local results = bench_helpers.benchmark("refresh() - small buffer (5 marks, 100 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh medium buffer"] = function()
  bench_helpers.setup_local_marks(child, 5, 1000)
  local results = bench_helpers.benchmark("refresh() - medium buffer (5 marks, 1000 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh large buffer"] = function()
  bench_helpers.setup_local_marks(child, 5, 5000)
  local results = bench_helpers.benchmark("refresh() - large buffer (5 marks, 5000 lines)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Consecutive refresh calls (simulating rapid autocmd triggers)
T["consecutive refresh calls"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  local results = bench_helpers.benchmark("refresh() - 100 consecutive calls", function()
    for _ = 1, 100 do
      child.lua([[require("guttermarks").refresh()]])
    end
  end, 10) -- Only 10 iterations since each iteration runs 100 refreshes
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Refresh with custom sign functions vs static strings
T["refresh with static sign strings"] = function()
  child.lua([[
    require("guttermarks").setup({
      local_mark = { sign = "L" },
      global_mark = { sign = "G" },
    })
  ]])
  bench_helpers.setup_mixed_marks(child, 10, 5, 500)
  local results = bench_helpers.benchmark("refresh() - static sign strings (15 marks)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with custom sign functions"] = function()
  child.lua([[
    require("guttermarks").setup({
      local_mark = {
        sign = function(mark)
          return mark.mark:sub(2)
        end
      },
      global_mark = {
        sign = function(mark)
          return mark.mark:sub(2):lower()
        end
      },
    })
  ]])
  bench_helpers.setup_mixed_marks(child, 10, 5, 500)
  local results = bench_helpers.benchmark("refresh() - custom sign functions (15 marks)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Refresh with special marks enabled vs disabled
T["refresh with special marks disabled"] = function()
  child.lua([[
    require("guttermarks").setup({
      special_mark = { enabled = false },
    })
  ]])
  bench_helpers.setup_local_marks(child, 10, 500)
  local results = bench_helpers.benchmark("refresh() - special marks disabled (10 local)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh with special marks enabled"] = function()
  child.lua([[
    require("guttermarks").setup({
      special_mark = { enabled = true },
    })
  ]])
  bench_helpers.setup_local_marks(child, 10, 500)
  -- Set some special marks
  child.cmd("normal! gg")
  child.cmd("normal! '")
  child.cmd("normal! 50G")
  child.cmd("normal! '")

  local results = bench_helpers.benchmark("refresh() - special marks enabled (10 local + special)", function()
    child.lua([[require("guttermarks").refresh()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

return T
