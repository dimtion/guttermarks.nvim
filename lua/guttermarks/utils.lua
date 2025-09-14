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

return M
