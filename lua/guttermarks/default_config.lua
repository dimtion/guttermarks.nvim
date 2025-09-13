return {
  local_mark = {
    enabled = true,
    sign = nil,
    highlight_group = "GutterMarksLocal",
    priority = 10,
  },
  global_mark = {
    enabled = true,
    sign = nil,
    highlight_group = "GutterMarksGlobal",
    priority = 11,
  },
  special_mark = {
    enabled = false,
    sign = nil,
    marks = { "'", "^", ".", "[", "]", "<", ">", '"', "`", '"', "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" },
    highlight_group = "GutterMarksSpecial",
    priority = 10,
  },
  autocmd_triggers = {
    "BufEnter",
    "BufWritePost",
    "TextChanged",
    "TextChangedI",
  },
  excluded_filetypes = {
    "NvimTree",
    "",
  },
  excluded_buftypes = {
    "terminal",
    "prompt",
    "quickfix",
  },
}
