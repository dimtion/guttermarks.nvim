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

T["marks_equal"] = MiniTest.new_set()

T["marks_equal"]["equal empty lists"] = function()
  eq(utils.marks_equal({}, {}), true)
end

T["marks_equal"]["equal single mark"] = function()
  local mark = { mark = "a", line = 1, type = "local_mark" }
  eq(utils.marks_equal({ mark }, { mark }), true)
end

T["marks_equal"]["different lengths"] = function()
  local m1 = { mark = "a", line = 1, type = "local_mark" }
  local m2 = { mark = "b", line = 2, type = "local_mark" }
  eq(utils.marks_equal({ m1 }, { m1, m2 }), false)
  eq(utils.marks_equal({ m1, m2 }, { m1 }), false)
end

T["marks_equal"]["different mark name"] = function()
  local m1 = { mark = "a", line = 1, type = "local_mark" }
  local m2 = { mark = "b", line = 1, type = "local_mark" }
  eq(utils.marks_equal({ m1 }, { m2 }), false)
end

T["marks_equal"]["different line"] = function()
  local m1 = { mark = "a", line = 1, type = "local_mark" }
  local m2 = { mark = "a", line = 2, type = "local_mark" }
  eq(utils.marks_equal({ m1 }, { m2 }), false)
end

T["marks_equal"]["different type"] = function()
  local m1 = { mark = "a", line = 1, type = "local_mark" }
  local m2 = { mark = "a", line = 1, type = "global_mark" }
  eq(utils.marks_equal({ m1 }, { m2 }), false)
end

T["marks_equal"]["multiple equal marks"] = function()
  local marks1 = {
    { mark = "a", line = 1, type = "local_mark" },
    { mark = "B", line = 5, type = "global_mark" },
  }
  local marks2 = {
    { mark = "a", line = 1, type = "local_mark" },
    { mark = "B", line = 5, type = "global_mark" },
  }
  eq(utils.marks_equal(marks1, marks2), true)
end

T["marks_equal"]["order matters"] = function()
  local marks1 = {
    { mark = "a", line = 1, type = "local_mark" },
    { mark = "b", line = 2, type = "local_mark" },
  }
  local marks2 = {
    { mark = "b", line = 2, type = "local_mark" },
    { mark = "a", line = 1, type = "local_mark" },
  }
  eq(utils.marks_equal(marks1, marks2), false)
end

return T
