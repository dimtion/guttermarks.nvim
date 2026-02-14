local M = {}

---Action to delete a mark at current cursor position
---or selected position
---@param bufnr number|nil - buffer number to use (default to current buffer)
---@param line number|nil - line number to use (default to cursor line)
M.delete_mark = function(bufnr, line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  line = line or vim.api.nvim_win_get_cursor(0)[1]

  for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
    if m.pos[2] == line and m.mark:match("^'[a-z]") then
      vim.api.nvim_buf_del_mark(bufnr, m.mark:sub(2))
    end
  end

  for _, m in ipairs(vim.fn.getmarklist()) do
    if m.pos[1] == bufnr and m.pos[2] == line and m.mark:match("^'[A-Z]") then
      vim.api.nvim_del_mark(m.mark:sub(2))
    end
  end
  require("guttermarks").refresh()
end

---Action to send marks to quickfix list
---@param opts table|nil - options table with local_mark, global_mark, special_mark booleans
M.marks_to_quickfix = function(opts)
  opts = opts or {}
  local local_mark = opts.local_mark ~= false
  local global_mark = opts.global_mark ~= false
  local special_mark = opts.special_mark == true

  local utils = require("guttermarks.utils")
  local qf_items = {}

  if local_mark then
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(bufnr) then
        local buffer_marks = vim.fn.getmarklist(bufnr)
        for _, mark in ipairs(buffer_marks) do
          local mark_name = mark.mark:sub(2)

          if utils.is_lower(mark_name) then
            local text = string.format("Mark %s (Local)", mark_name)
            local filename = vim.api.nvim_buf_get_name(bufnr)

            table.insert(qf_items, {
              bufnr = bufnr,
              filename = filename,
              lnum = mark.pos[2],
              col = mark.pos[3],
              text = text,
            })
          end
        end
      end
    end
  end

  local marks = vim.fn.getmarklist()
  for _, mark in ipairs(marks) do
    local mark_name = mark.mark:sub(2)
    local ext = ""
    local should_include = false

    if utils.is_upper(mark_name) then
      ext = " (Global)"
      should_include = global_mark
    elseif not utils.is_letter(mark_name) then
      ext = " (Special)"
      should_include = special_mark
    end

    if should_include then
      local text = string.format("Mark %s%s", mark_name, ext)

      table.insert(qf_items, {
        bufnr = mark.pos[1],
        filename = mark.file,
        lnum = mark.pos[2],
        col = mark.pos[3],
        text = text,
      })
    end
  end

  vim.fn.setqflist(qf_items, "r")
end

---@param direction "forward"|"backward" - search forward or backward
---@param opts table|nil - options table with local_mark, global_mark, wrap booleans
local function navigate_buf_mark(direction, opts)
  opts = opts or {}
  local local_mark = opts.local_mark ~= false
  local global_mark = opts.global_mark ~= false
  local wrap = opts.wrap ~= false

  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local current_line = cursor[1]
  local current_col = cursor[2]

  -- Collect all relevant marks into one list
  local all_marks = {}

  if local_mark then
    for _, m in ipairs(vim.fn.getmarklist(bufnr)) do
      if m.mark:match("^'[a-z]") then
        table.insert(all_marks, { line = m.pos[2], col = m.pos[3] - 1, mark = m.mark:sub(2) })
      end
    end
  end

  if global_mark then
    for _, m in ipairs(vim.fn.getmarklist()) do
      if m.pos[1] == bufnr and m.mark:match("^'[A-Z]") then
        table.insert(all_marks, { line = m.pos[2], col = m.pos[3] - 1, mark = m.mark:sub(2) })
      end
    end
  end

  table.sort(all_marks, function(a, b)
    if a.line ~= b.line then
      return a.line < b.line
    end
    return a.col < b.col
  end)

  -- Scan sorted list for the nearest mark in the requested direction
  local target_mark = nil
  if direction == "forward" then
    for _, m in ipairs(all_marks) do
      if m.line > current_line or (m.line == current_line and m.col > current_col) then
        target_mark = m
        break
      end
    end
    if not target_mark and wrap then
      target_mark = all_marks[1]
    end
  else
    for i = #all_marks, 1, -1 do
      if all_marks[i].line < current_line or (all_marks[i].line == current_line and all_marks[i].col < current_col) then
        target_mark = all_marks[i]
        break
      end
    end
    if not target_mark and wrap then
      target_mark = all_marks[#all_marks]
    end
  end

  if target_mark then
    vim.api.nvim_win_set_cursor(0, { target_mark.line, target_mark.col })
  end
end

---Navigate to the next mark in buffer (forward)
---@param opts table|nil - options table with local_mark, global_mark, wrap booleans
M.next_buf_mark = function(opts)
  navigate_buf_mark("forward", opts)
end

---Navigate to the previous mark in buffer (backward)
---@param opts table|nil - options table with local_mark, global_mark, wrap booleans
M.prev_buf_mark = function(opts)
  navigate_buf_mark("backward", opts)
end

return M
