if vim.g.loaded_guttermarks == 1 then
  return
end
vim.g.loaded_guttermarks = 1

require("guttermarks").init()

local function guttermarks_command(opts)
  local subcommand = opts.fargs[1]

  if subcommand == "toggle" then
    require("guttermarks").toggle()
  elseif subcommand == "enable" then
    require("guttermarks").enable(true)
  elseif subcommand == "disable" then
    require("guttermarks").enable(false)
  elseif subcommand == "refresh" then
    require("guttermarks").refresh()
  else
    vim.notify("GutterMarks: Unknown subcommand '" .. (subcommand or "") .. "'", vim.log.levels.ERROR)
    vim.notify("Available subcommands: toggle, enable, disable, refresh", vim.log.levels.INFO)
  end
end

local function guttermarks_complete(arg_lead)
  local subcommands = { "toggle", "enable", "disable", "refresh" }
  local matches = {}

  for _, subcommand in ipairs(subcommands) do
    if vim.startswith(subcommand, arg_lead) then
      table.insert(matches, subcommand)
    end
  end

  return matches
end

vim.api.nvim_create_user_command("GutterMarks", guttermarks_command, {
  nargs = 1,
  desc = "GutterMarks plugin commands",
  complete = guttermarks_complete,
})
