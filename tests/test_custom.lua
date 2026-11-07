local custom = require("custom")

local function eqlist(a, b)
  T.eq(#a, #b)
  for i = 1, #a do T.eq(a[i], b[i]) end
end

return {
  test_custom_roundtrip = function()
    local cats = {
      { name = "Potes du lycée", words = { "Étienne", "la crêpe à Zoë" } },
      { name = "Ça va", words = { "où ça", "garçon" } },
    }
    local r = custom.parse(custom.serialize(cats))
    T.eq(#r, 2)
    for i = 1, 2 do
      T.eq(r[i].name, cats[i].name)
      eqlist(r[i].words, cats[i].words)
    end
  end,
  test_custom_damaged = function()
    local r = custom.parse("mot sans catégorie\n[A]\nx\n[\n")
    T.eq(#r, 1)
    T.eq(r[1].name, "A")
    eqlist(r[1].words, { "x" })
    T.eq(#custom.parse(nil), 0)
  end,
  test_custom_parse_skips_bad_headers = function()
    local r = custom.parse("[A]\nx\n[a]\ny\n[Soirée]\nz\n[B]\nw\n[" .. string.rep("q", 30) .. "]\nv\n")
    T.eq(#r, 2)
    T.eq(r[1].name, "A"); eqlist(r[1].words, { "x" })
    T.eq(r[2].name, "B"); eqlist(r[2].words, { "w" })
  end,
  test_custom_names = function()
    local cats = { { name = "Potes", words = {} } }
    local ok, why = custom.valid_name(cats, "")
    T.eq(ok, nil); T.eq(why, "vide")
    ok, why = custom.valid_name(cats, string.rep("a", 25))
    T.eq(why, "trop long")
    T.ok(custom.valid_name(cats, string.rep("é", 24)))
    ok, why = custom.valid_name(cats, "potes")
    T.eq(why, "existe")
    ok, why = custom.valid_name(cats, "Soirée")
    T.eq(why, "réservé")
    ok, why = custom.valid_name(cats, "SOIRÉE")
    T.eq(why, "réservé")
    T.eq(custom.valid_name(cats, "potes", 1), true)
  end,
  test_custom_words = function()
    local cat = { name = "A", words = {} }
    local ok, why = custom.add_word(cat, string.rep("a", 41))
    T.eq(ok, nil); T.eq(why, "trop long")
    T.eq(custom.add_word(cat, "  Bac   de philo "), true)
    eqlist(cat.words, { "Bac de philo" })
    ok, why = custom.add_word(cat, "bac de philo")
    T.eq(why, "existe")
    ok, why = custom.add_word(cat, "   ")
    T.eq(why, "vide")
    T.eq(#cat.words, 1)
  end,
  test_custom_edit_word = function()
    local cat = { name = "A", words = { "un", "deux" } }
    T.eq(custom.set_word(cat, 1, "UN"), true)
    eqlist(cat.words, { "UN", "deux" })
    local ok, why = custom.set_word(cat, 1, "deux")
    T.eq(why, "existe")
  end,
  test_custom_valid_word_is_pure = function()
    local cat = { name = "A", words = { "un" } }
    T.eq(custom.valid_word(cat, "deux"), true)
    T.eq(#cat.words, 1)
    T.eq(custom.valid_word(cat, "UN", 1), true)
    local ok, why = custom.valid_word(cat, "un")
    T.eq(why, "existe")
  end,
  test_custom_as_categories = function()
    local cats = { { name = "Vide", words = {} }, { name = "Potes", words = { "a", "b" } } }
    local r = custom.as_categories(cats)
    T.eq(#r, 1)
    T.eq(r[1].id, "perso:Potes")
    T.eq(r[1].label, "Potes")
    eqlist(r[1].words, { "a", "b" })
  end,
  test_custom_safe_chars = function()
    local cats = { { name = "A,B", words = {} } }
    T.eq(custom.valid_name({}, "A,B"), true)
    local cat = { name = "A", words = {} }
    custom.add_word(cat, "[crochet]")
    local r = custom.parse(custom.serialize({ cat }))
    T.eq(#r, 1)
    T.eq(#r[1].words, 1)
  end,
}
