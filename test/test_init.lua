-- Basic test to verify the extension loads correctly

local MiniTest = require("mini.test")
local expect = MiniTest.expect

local T = MiniTest.new_set({
  hooks = {
    pre_case = function()
      -- Reset any global state
    end,
  },
})

T["Extension loads"] = function()
  local ok, extension = pcall(require, "guttermarks")
  expect.equality(ok, true)
  expect.equality(type(extension.setup), "function")
  -- expect.equality(type(extension.exports), 'table')
end

return T
