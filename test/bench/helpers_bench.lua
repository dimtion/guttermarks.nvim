-- Benchmarking helpers for guttermarks.nvim performance tests
local M = {}

--- Run a benchmark function multiple times and collect statistics
---@param name string Benchmark name for reporting
---@param fn function Function to benchmark
---@param iterations number Number of iterations to run (default: 100)
---@return table results Statistics table with mean, median, min, max, stddev
function M.benchmark(name, fn, iterations)
  iterations = iterations or 100
  local times = {}

  for _ = 1, iterations do
    -- Force garbage collection before each run for consistent measurements
    collectgarbage("collect")

    local start = vim.loop.hrtime()
    fn()
    local duration = (vim.loop.hrtime() - start) / 1e6 -- Convert ns to ms
    table.insert(times, duration)
  end

  -- Calculate statistics
  table.sort(times)
  local sum = 0
  for _, t in ipairs(times) do
    sum = sum + t
  end
  local mean = sum / #times
  local median = times[math.floor(#times / 2) + 1]

  -- Calculate standard deviation
  local variance_sum = 0
  for _, t in ipairs(times) do
    variance_sum = variance_sum + (t - mean) ^ 2
  end
  local stddev = math.sqrt(variance_sum / #times)

  return {
    name = name,
    iterations = iterations,
    mean = mean,
    median = median,
    min = times[1],
    max = times[#times],
    stddev = stddev,
  }
end

--- Format benchmark results as a compact note for MiniTest.add_note()
---@param results table Benchmark results from M.benchmark
---@return string Compact formatted results
function M.format_note(results)
  return string.format(
    "it=%.4d\nmean=%.3fms median=%.3fms min=%.3fms max=%.3fms stddev=%.3fms",
    -- results.name,
    results.iterations,
    results.mean,
    results.median,
    results.min,
    results.max,
    results.stddev
  )
end

--- Create a buffer with N marks at distributed positions
---@param child table MiniTest child process
---@param num_lines number Number of lines in buffer
---@param marks table Array of mark names (e.g., {"a", "b", "c"})
---@return number bufnr Created buffer number
function M.create_buffer_with_marks(child, num_lines, marks)
  local lines = {}
  for i = 1, num_lines do
    table.insert(lines, string.format("Line %d", i))
  end

  child.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  -- Distribute marks evenly throughout the buffer
  for i, mark in ipairs(marks) do
    local line = math.floor((i / (#marks + 1)) * num_lines) + 1
    child.api.nvim_win_set_cursor(0, { line, 0 })
    child.cmd("normal! m" .. mark)
  end

  return child.api.nvim_get_current_buf()
end

--- Create multiple local marks (a-z subset)
---@param child table MiniTest child process
---@param count number Number of marks to create (1-26)
---@param num_lines number Number of lines in buffer
function M.setup_local_marks(child, count, num_lines)
  local marks = {}
  for i = 1, math.min(count, 26) do
    table.insert(marks, string.char(96 + i)) -- 'a' to 'z'
  end
  return M.create_buffer_with_marks(child, num_lines, marks)
end

--- Create multiple global marks (A-Z subset)
---@param child table MiniTest child process
---@param count number Number of marks to create (1-26)
---@param num_lines number Number of lines in buffer
function M.setup_global_marks(child, count, num_lines)
  local marks = {}
  for i = 1, math.min(count, 26) do
    table.insert(marks, string.char(64 + i)) -- 'A' to 'Z'
  end
  return M.create_buffer_with_marks(child, num_lines, marks)
end

--- Setup a realistic buffer with mixed marks
---@param child table MiniTest child process
---@param local_count number Number of local marks
---@param global_count number Number of global marks
---@param num_lines number Number of lines in buffer
function M.setup_mixed_marks(child, local_count, global_count, num_lines)
  local lines = {}
  for i = 1, num_lines do
    table.insert(lines, string.format("Line %d content here", i))
  end

  child.api.nvim_buf_set_lines(0, 0, -1, false, lines)

  -- Set local marks
  for i = 1, math.min(local_count, 26) do
    local mark = string.char(96 + i) -- 'a' to 'z'
    local line = math.floor((i / (local_count + 1)) * num_lines) + 1
    child.api.nvim_win_set_cursor(0, { line, 0 })
    child.cmd("normal! m" .. mark)
  end

  -- Set global marks
  for i = 1, math.min(global_count, 26) do
    local mark = string.char(64 + i) -- 'A' to 'Z'
    local line = math.floor((i / (global_count + 1)) * num_lines) + 1
    child.api.nvim_win_set_cursor(0, { line, 0 })
    child.cmd("normal! m" .. mark)
  end

  return child.api.nvim_get_current_buf()
end

return M
