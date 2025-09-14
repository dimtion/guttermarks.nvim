---@class guttermarks.MarkConfig
---@field enabled? boolean Whether this mark type is enabled
---@field sign? function (optional) Function to display custom sign in column
---@field highlight_group? string Highlight group name for the sign
---@field priority? integer Priority for sign placement

---@class guttermarks.SpecialMarkConfig : guttermarks.MarkConfig
---@field marks? string[] List of special mark characters to display

---@class guttermarks.Config
---@field local_mark? guttermarks.MarkConfig Configuration for local marks (a-z)
---@field global_mark? guttermarks.MarkConfig Configuration for global marks (A-Z)
---@field special_mark? guttermarks.SpecialMarkConfig Configuration for special marks
---@field autocmd_triggers? string[] List of autocmd events that trigger mark updates
---@field excluded_filetypes? string[] List of filetypes to exclude from mark display
---@field excluded_buftypes? string[] List of buffer types to exclude from mark display

---Default configuration
---@type guttermarks.Config
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
