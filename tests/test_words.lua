local words = require("words")
local categories = require("categories")

return {
  test_parse_cleans = function()
    local r = words.parse("  frigo \n\n# note\nbus\nfrigo\r\n")
    T.eq(#r, 2)
    T.eq(r[1], "frigo")
    T.eq(r[2], "bus")
  end,

  test_words_utf8 = function()
    local r = words.parse("Œuf\nÉcole\nAujourd’hui\n")
    T.eq(r[1], "Œuf")
    T.eq(r[2], "École")
    T.eq(r[3], "Aujourd’hui")
  end,

  test_load_skips_empty_category = function()
    local r = words.load(function(path)
      if path == "words/melange.txt" then return "a\nb" end
      if path == "words/soiree.txt" then return "# rien\n" end
      return nil
    end)
    T.eq(#r.melange, 2)
    T.eq(#r.categories, 0)
  end,

  test_load_keeps_order = function()
    local r = words.load(function(path) return "mot" end)
    T.eq(#r.categories, #categories.LIST)
    for i, c in ipairs(categories.LIST) do
      T.eq(r.categories[i].id, c.id)
      T.eq(r.categories[i].label, c.label)
      T.eq(r.categories[i].words[1], "mot")
    end
  end,
}
