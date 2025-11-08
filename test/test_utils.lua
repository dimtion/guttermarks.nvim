local MiniTest = require("mini.test")
local T = MiniTest.new_set()
local eq = MiniTest.expect.equality
local helpers = dofile("test/helpers.lua")

local utils = require("guttermarks.utils")

T["alphabet_lower"] = MiniTest.new_set({
  parametrize = helpers.alphabet_lower,
})

T["alphabet_upper"] = MiniTest.new_set({
  parametrize = helpers.alphabet_upper,
})

T["non_alphabet"] = MiniTest.new_set()

T["alphabet_lower"]["is_lower"] = function(x)
  eq(utils.is_lower(x), true)
end

T["alphabet_lower"]["is_upper"] = function(x)
  eq(utils.is_upper(x), false)
end

T["alphabet_lower"]["is_letter"] = function(x)
  eq(utils.is_letter(x), true)
end

T["alphabet_upper"]["is_lower"] = function(x)
  eq(utils.is_lower(x), false)
end

T["alphabet_upper"]["is_upper"] = function(x)
  eq(utils.is_upper(x), true)
end

T["alphabet_upper"]["is_letter"] = function(x)
  eq(utils.is_letter(x), true)
end

T["non_alphabet"]["is_upper"] = function()
  eq(utils.is_upper("}"), false)
end

T["non_alphabet"]["is_lower"] = function()
  eq(utils.is_lower("}"), false)
end

T["non_alphabet"]["is_letter"] = function()
  eq(utils.is_letter("}"), false)
end

return T
