local settings = require("settings")

local known = { maison = true, bouffe = true, transport = true, ["boulot-ecole"] = true, sante = true, soiree = true }

local function count(t) local n = 0 for _ in pairs(t) do n = n + 1 end return n end

return {
  test_settings_roundtrip = function()
    local s = { categories = { soiree = true, bouffe = true }, timer = 60 }
    local text = settings.serialize(s)
    T.eq(text, "timer=60\ncategories=bouffe,soiree\n")
    local r = settings.parse(text, known)
    T.eq(r.timer, 60)
    T.eq(count(r.categories), 2)
    T.ok(r.categories.soiree and r.categories.bouffe)
  end,
  test_settings_garbage = function()
    local r = settings.parse("@@@\ntimer=45\n", known)
    T.eq(r.timer, 0)
    T.eq(count(r.categories), 0)
  end,
  test_settings_nil = function()
    local r = settings.parse(nil, known)
    T.eq(r.timer, 0)
    T.eq(count(r.categories), 0)
  end,
  test_settings_unknown_category = function()
    local r = settings.parse("categories=soiree,vacances", { soiree = true })
    T.eq(count(r.categories), 1)
    T.ok(r.categories.soiree)
  end,
  test_settings_custom_order = function()
    local k = { bouffe = true, ["perso:Zèbre"] = true, ["perso:Potes du lycée"] = true }
    local s = { categories = { ["perso:Zèbre"] = true, ["perso:Potes du lycée"] = true, bouffe = true }, timer = 30 }
    local text = settings.serialize(s)
    T.eq(text, "timer=30\ncategories=bouffe,perso:Potes du lycée,perso:Zèbre\n")
    local r = settings.parse(text, k)
    T.eq(count(r.categories), 3)
    T.ok(r.categories["perso:Potes du lycée"])
  end,
  test_settings_field_by_field = function()
    local r = settings.parse("timer=90\r\ncategories=nope\n", known)
    T.eq(r.timer, 90)
    T.eq(count(r.categories), 0)
  end,
}
