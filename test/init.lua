-- Minimal init script
local root = vim.fn.fnamemodify(debug.getinfo(1).source:match("@(.*)"), ":h:h")
local deps_path = root .. "/.deps"

local deps = {
  "mini.test",
}

for _, dep in ipairs(deps) do
  local dep_path = deps_path .. "/" .. dep
  if vim.fn.isdirectory(dep_path) == 1 then
    vim.opt.runtimepath:append(dep_path)
  end
end

vim.opt.runtimepath:append(root)

require("mini.test").setup({
  collect = {
    find_files = function()
      return vim.fn.globpath("test", "**/test_*.lua", true, true)
    end,
  },
})
