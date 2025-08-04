if vim.g.loaded_guttermarks == 1 then
  return
end
vim.g.loaded_guttermarks = 1

require("guttermarks").setup()

vim.api.nvim_create_user_command("GutterMarksToggle", function()
  require("guttermarks").toggle()
end, {})
vim.api.nvim_create_user_command("GutterMarksEnable", function()
  require("guttermarks").enable(true)
end, {})
vim.api.nvim_create_user_command("GutterMarksDisable", function()
  require("guttermarks").enable(false)
end, {})
