local textfit = require("textfit")

local function measure(text, size) return #text * size * 0.8, size end
local SIZES = { 120, 96, 72, 56, 40, 32, 26, 22 }

return {
  test_textfit_short = function()
    local size, lines = textfit.fit("Frigo", 680, 300, SIZES, measure)
    T.eq(size, 120)
    T.eq(#lines, 1)
  end,
  test_textfit_long_phrase = function()
    local size, lines = textfit.fit("Brosse à dents électrique", 680, 300, SIZES, measure)
    T.ok(#lines >= 2 and #lines <= 3, "lines: " .. #lines)
    T.ok(#lines * size <= 300, "too tall")
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

  -- Close to Clebard Tall's real metrics (about 0.86 x size per lowercase letter).
  test_textfit_40_char_word_stays_in_box = function()
    local function real(text, size) return #text * size * 0.86, size * 1.45 end
    local word = string.rep("a", 40)
    local size, lines = textfit.fit(word, 680, 300, SIZES, real)
    local h = 0
    for _, l in ipairs(lines) do
      local w, lh = real(l, size)
      T.ok(w <= 680, "line too wide: " .. w)
      h = h + lh
    end
    T.ok(h <= 300, "too tall: " .. h)
    T.eq(table.concat(lines), word)
  end,
  test_textfit_40_char_phrase_stays_in_box = function()
    local function real(text, size) return #text * size * 0.86, size * 1.45 end
    local phrase = "La fois où on a raté le dernier bus x"
    phrase = phrase .. string.rep("z", 40 - #phrase)
    T.eq(#phrase, 40)
    local size, lines = textfit.fit(phrase, 680, 300, SIZES, real)
    T.ok(#lines <= 3, "lines: " .. #lines)
    local h = 0
    for _, l in ipairs(lines) do
      local w, lh = real(l, size)
      T.ok(w <= 680, "line too wide: " .. w)
      h = h + lh
    end
    T.ok(h <= 300, "too tall: " .. h)
    T.eq(table.concat(lines, " "), phrase)
  end,
  test_textfit_three_lines = function()
    local size, lines = textfit.fit("un deux trois quatre cinq six sept huit neuf dix onze", 680, 300, SIZES, measure)
    T.ok(#lines >= 2 and #lines <= 3)
    for _, l in ipairs(lines) do T.ok(measure(l, size) <= 680, "line too wide") end
    T.ok(#lines * size <= 300)
  end,
}
