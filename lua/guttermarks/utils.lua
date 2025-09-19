local M = {}

---@param char string
function M.is_upper(char)
  return (65 <= char:byte() and char:byte() <= 90)
end

---@param char string
function M.is_lower(char)
  return (97 <= char:byte() and char:byte() <= 122)
end

---@param char string
function M.is_letter(char)
  return M.is_upper(char) or M.is_lower(char)
end

---@param bufnr number
---@param line number
function M.is_valid_mark(bufnr, line)
  return (0 < line and line <= vim.api.nvim_buf_line_count(bufnr))
end

---Returns the list of enabled and valid marks in the selected buffer
---@param bufnr number Buffer number
---@param config guttermarks.Config Configuration
---@return guttermarks.Mark[]
function M.get_buffer_marks(bufnr, config)
  local marks = {}

  if config.local_mark.enabled then
    for _, mark in ipairs(vim.fn.getmarklist("%")) do
      local m = mark.mark:sub(2, 3)
      if M.is_letter(m) and M.is_valid_mark(bufnr, mark.pos[2]) then
        table.insert(marks, {
          mark = m,
          line = mark.pos[2],
          type = "local_mark",
        })
      end
    end
  end

  if config.global_mark.enabled then
    for _, mark in ipairs(vim.fn.getmarklist()) do
      local m = mark.mark:sub(2, 3)
      if mark.pos[1] == bufnr and M.is_letter(m) and M.is_valid_mark(bufnr, mark.pos[2]) then
        table.insert(marks, {
          mark = m,
          line = mark.pos[2],
          type = "global_mark",
        })
      end
    end
  end

  if config.special_mark.enabled then
    for _, mark in ipairs(config.special_mark.marks) do
      local pos = vim.api.nvim_buf_get_mark(bufnr, mark)
      if M.is_valid_mark(bufnr, pos[1]) then
        table.insert(marks, {
          mark = mark,
          line = pos[1],
          type = "special_mark",
        })
      end
    end
  end

  return marks
end

return M
