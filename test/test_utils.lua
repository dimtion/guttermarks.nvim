local MiniTest = require("mini.test")
local T = MiniTest.new_set()
local eq = MiniTest.expect.equality

local utils = require("guttermarks.utils")

-- stylua: ignore
T["alphabet_lower"] = MiniTest.new_set({
  parametrize = {
    { "a" }, { "b" }, { "c" }, { "d" }, { "e" }, { "f" }, { "g" }, { "h" }, { "i" }, { "j" }, { "k" }, { "l" }, { "m" },
    { "n" }, { "o" }, { "p" }, { "q" }, { "r" }, { "s" }, { "t" }, { "u" }, { "v" }, { "w" }, { "x" }, { "y" }, { "z" },
  },
})

-- stylua: ignore
T["alphabet_upper"] = MiniTest.new_set({
  parametrize = {
    { "A" }, { "B" }, { "C" }, { "D" }, { "E" }, { "F" }, { "G" }, { "H" }, { "I" }, { "J" }, { "K" }, { "L" }, { "M" },
    { "N" }, { "O" }, { "P" }, { "Q" }, { "R" }, { "S" }, { "T" }, { "U" }, { "V" }, { "W" }, { "X" }, { "Y" }, { "Z" },
  },
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

T["non_alphabet"]["is_upper"] = function()
  eq(utils.is_lower("}"), false)
end

T["non_alphabet"]["is_letter"] = function()
  eq(utils.is_letter("a "), true)
end

return T
