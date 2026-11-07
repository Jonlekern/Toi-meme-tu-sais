local textfit = require("textfit")

local function measure(text, size) return #text * size * 0.8, size end
local SIZES = { 120, 96, 72, 56, 40 }

return {
  test_textfit_short = function()
    local size, lines = textfit.fit("Frigo", 680, 300, SIZES, measure)
    T.eq(size, 120)
    T.eq(#lines, 1)
  end,
  test_textfit_long_phrase = function()
    local size, lines = textfit.fit("Brosse à dents électrique", 680, 300, SIZES, measure)
    T.eq(#lines, 2)
    for _, l in ipairs(lines) do T.ok(measure(l, size) <= 680, "line too wide") end
  end,
  test_textfit_single_long_word = function()
    local size, lines = textfit.fit("Anticonstitutionnellement", 680, 300, SIZES, measure)
    T.eq(#lines, 1)
    T.ok(size < 120)
    T.ok(measure(lines[1], size) <= 680 or size == 40)
  end,
  test_textfit_extra_spaces = function()
    local _, lines = textfit.fit("Gueule  de bois  ", 680, 300, SIZES, measure)
    T.ok(#lines >= 1 and #lines <= 2)
    for _, l in ipairs(lines) do T.ok(#l > 0, "empty line") ; T.ok(not l:find("^ ") and not l:find(" $")) end
  end,
}
