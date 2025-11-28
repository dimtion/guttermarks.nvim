-- Performance benchmarks for cache effectiveness
local bench_helpers = dofile("test/bench/helpers_bench.lua")
local child = MiniTest.new_child_neovim()

local REFRESH_CALLS = 1000

local T = MiniTest.new_set({
  hooks = {
    pre_once = function()
      child.restart({ "-u", "test/bench/init.lua" })
      child.lua([[
        require("guttermarks").setup({
          special_mark = { enabled = true }
        })
      ]])
    end,
    post_once = function()
      child.stop()
    end,
  },
})

-- Benchmark: Cache hit vs cache miss with light usage
T["refresh with cache - light"] = function()
  bench_helpers.setup_local_marks(child, 3, 500)
  local results = bench_helpers.benchmark("refresh() with cache - light (3 marks, 500 lines)", function()
    for _ = 1, REFRESH_CALLS do
      child.lua([[require("guttermarks").refresh()]])
    end
  end, 10)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh without cache - light"] = function()
  bench_helpers.setup_local_marks(child, 3, 500)
  local bufnr = child.api.nvim_get_current_buf()
  local results = bench_helpers.benchmark("refresh() without cache - light (3 marks, 500 lines)", function()
    for _ = 1, REFRESH_CALLS do
      child.lua("require('guttermarks')._marks_cache[" .. bufnr .. "] = nil")
      child.lua([[require("guttermarks").refresh()]])
    end
  end, 10)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Cache hit vs cache miss with heavy usage
T["refresh with cache - heavy"] = function()
  bench_helpers.setup_mixed_marks(child, 26, 26, 5000)
  child.cmd("normal! gg")
  child.cmd("normal! ma")
  child.cmd("normal! 1000G")
  child.cmd("normal! ma")
  child.cmd("normal! 2500G")
  local results = bench_helpers.benchmark("refresh() with cache - heavy (52 marks, 5000 lines)", function()
    for _ = 1, REFRESH_CALLS do
      child.lua([[require("guttermarks").refresh()]])
    end
  end, 10)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["refresh without cache - heavy"] = function()
  bench_helpers.setup_mixed_marks(child, 26, 26, 5000)
  child.cmd("normal! gg")
  child.cmd("normal! ma")
  child.cmd("normal! 1000G")
  child.cmd("normal! ma")
  child.cmd("normal! 2500G")
  local bufnr = child.api.nvim_get_current_buf()
  local results = bench_helpers.benchmark("refresh() without cache - heavy (52 marks, 5000 lines)", function()
    for _ = 1, REFRESH_CALLS do
      child.lua("require('guttermarks')._marks_cache[" .. bufnr .. "] = nil")
      child.lua([[require("guttermarks").refresh()]])
    end
  end, 10)
  MiniTest.add_note(bench_helpers.format_note(results))
end

return T
