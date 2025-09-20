local M = {}

local MiniTest = require("mini.test")

-- stylua: ignore
M.alphabet_lower = {
    { "a" }, { "b" }, { "c" }, { "d" }, { "e" }, { "f" }, { "g" }, { "h" }, { "i" }, { "j" }, { "k" }, { "l" }, { "m" },
    { "n" }, { "o" }, { "p" }, { "q" }, { "r" }, { "s" }, { "t" }, { "u" }, { "v" }, { "w" }, { "x" }, { "y" }, { "z" },
}

-- stylua: ignore
M.alphabet_upper = {
    { "A" }, { "B" }, { "C" }, { "D" }, { "E" }, { "F" }, { "G" }, { "H" }, { "I" }, { "J" }, { "K" }, { "L" }, { "M" },
    { "N" }, { "O" }, { "P" }, { "Q" }, { "R" }, { "S" }, { "T" }, { "U" }, { "V" }, { "W" }, { "X" }, { "Y" }, { "Z" },
}

M.get_gutter = function(child)
  local ns = child.api.nvim_get_namespaces()["gutter_marks"]
  local bufnr = child.api.nvim_get_current_buf()
  MiniTest.expect.no_equality(ns, nil)
  MiniTest.expect.no_equality(bufnr, nil)
  local gutter = child.api.nvim_buf_get_extmarks(bufnr, ns, 0, -1, {
    details = true,
  })
  return gutter
end

return M
