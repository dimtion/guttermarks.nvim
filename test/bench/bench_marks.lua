-- Performance benchmarks for guttermarks mark retrieval operations
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

-- Benchmark: get_buffer_marks() with varying configurations
T["get_buffer_marks with local marks only"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  local results = bench_helpers.benchmark("get_buffer_marks() - local marks only (10 marks)", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["get_buffer_marks with global marks only"] = function()
  bench_helpers.setup_global_marks(child, 10, 500)
  local results = bench_helpers.benchmark("get_buffer_marks() - global marks only (10 marks)", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["get_buffer_marks with mixed marks"] = function()
  bench_helpers.setup_mixed_marks(child, 10, 10, 500)
  local results = bench_helpers.benchmark("get_buffer_marks() - mixed marks (10 local + 10 global)", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["get_buffer_marks with all mark types"] = function()
  bench_helpers.setup_mixed_marks(child, 26, 26, 1000)
  local results = bench_helpers.benchmark("get_buffer_marks() - all marks (26 local + 26 global)", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Special marks retrieval overhead
T["get_buffer_marks without special marks"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  child.lua([[
    require("guttermarks").setup({
      special_mark = { enabled = false },
    })
  ]])
  local results = bench_helpers.benchmark("get_buffer_marks() - special marks disabled", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["get_buffer_marks with special marks"] = function()
  bench_helpers.setup_local_marks(child, 10, 500)
  child.lua([[
    require("guttermarks").setup({
      special_mark = { enabled = true },
    })
  ]])
  -- Create some special marks
  child.cmd("normal! gg")
  child.cmd("normal! '")
  child.cmd("normal! 100G")
  child.cmd("normal! '")

  local results = bench_helpers.benchmark("get_buffer_marks() - special marks enabled", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Mark validation overhead
T["is_valid_mark overhead"] = function()
  bench_helpers.setup_local_marks(child, 10, 5000)
  local results = bench_helpers.benchmark("is_valid_mark() - 1000 calls", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local bufnr = vim.api.nvim_get_current_buf()
      for i = 1, 1000 do
        local line = (i % 5000) + 1
        utils.is_valid_mark(bufnr, line)
      end
    ]])
  end, 50) -- Fewer iterations since we're doing 1000 checks per iteration
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: vim.fn.getmarklist performance
T["vim.fn.getmarklist for current buffer"] = function()
  bench_helpers.setup_local_marks(child, 26, 500)
  local results = bench_helpers.benchmark("vim.fn.getmarklist('%') - 26 local marks", function()
    child.lua([[vim.fn.getmarklist("%")]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

T["vim.fn.getmarklist for all buffers"] = function()
  -- Create multiple buffers with global marks
  child.lua([[
    for i = 1, 5 do
      vim.cmd("enew")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {"Line 1", "Line 2", "Line 3"})
    end
  ]])
  bench_helpers.setup_global_marks(child, 26, 100)

  local results = bench_helpers.benchmark("vim.fn.getmarklist() - all buffers (26 global marks)", function()
    child.lua([[vim.fn.getmarklist()]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Multiple buffers with global marks
T["get_buffer_marks with multiple buffers"] = function()
  -- Create 10 buffers
  child.lua([[
    for i = 1, 10 do
      vim.cmd("enew")
      vim.api.nvim_buf_set_lines(0, 0, -1, false, {"Line 1", "Line 2", "Line 3"})
    end
  ]])

  -- Add global marks across buffers
  for i = 1, 10 do
    local mark = string.char(64 + i) -- A-J
    child.lua(string.format(
      [[
      vim.cmd("buffer %d")
      vim.api.nvim_win_set_cursor(0, {1, 0})
      vim.cmd("normal! m%s")
    ]],
      i,
      mark
    ))
  end

  local results = bench_helpers.benchmark("get_buffer_marks() - 10 buffers with global marks", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      local config = require("guttermarks.config")
      utils.get_buffer_marks(vim.api.nvim_get_current_buf(), config)
    ]])
  end)
  MiniTest.add_note(bench_helpers.format_note(results))
end

-- Benchmark: Character classification helpers
T["character classification helpers"] = function()
  local results = bench_helpers.benchmark("is_upper/is_lower/is_letter - 10000 calls", function()
    child.lua([[
      local utils = require("guttermarks.utils")
      for i = 1, 10000 do
        local char = string.char(65 + (i % 26)) -- A-Z
        utils.is_upper(char)
        utils.is_lower(char)
        utils.is_letter(char)
      end
    ]])
  end, 50)
  MiniTest.add_note(bench_helpers.format_note(results))
end

return T
