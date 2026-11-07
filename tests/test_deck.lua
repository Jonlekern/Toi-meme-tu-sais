local deck = require("deck")

local function seed() math.randomseed(1) return math.random end

local function lists()
  return {
    melange = { "m1", "m2", "m3", "m4", "m5" },
    categories = {
      { id = "soiree", label = "Soirée", words = { "s1", "s2", "s3", "s4" } },
      { id = "bouffe", label = "Bouffe", words = { "b1", "b2", "b3", "b4" } },
    },
  }
end

local function set(t) local s = {} for _, v in ipairs(t) do s[v] = true end return s end

return {
  test_bag_no_repeat_before_empty = function()
    local rng = seed()
    local items = {}
    for i = 1, 10 do items[i] = i end
    local bag = deck.bag(items, rng)
    local seen, n = {}, 0
    for _ = 1, 10 do
      local v = bag:draw()
      T.ok(not seen[v], "repeat " .. tostring(v))
      seen[v] = true
      n = n + 1
    end
    T.eq(n, 10)
  end,

  test_bag_no_back_to_back = function()
    local rng = seed()
    local bag = deck.bag({ "a", "b", "c" }, rng)
    local last
    for i = 1, 1000 do
      local v = bag:draw()
      T.ok(v ~= last, "back-to-back at " .. i)
      last = v
    end
  end,

  test_deck_melange_only = function()
    local rng = seed()
    local L = lists()
    local d = deck.new(L, {}, rng)
    local m = set(L.melange)
    for _ = 1, 200 do
      local w, c = d:next()
      T.ok(m[w], "word not in melange: " .. tostring(w))
      T.eq(c, nil)
    end
  end,

  test_deck_dice_gap = function()
    local rng = seed()
    local L = lists()
    local d = deck.new(L, { soiree = true }, rng)
    local gaps, total, since, started = { [2] = 0, [3] = 0, [4] = 0 }, 0, 0, false
    for _ = 1, 3000 do
      local _, c = d:next()
      since = since + 1
      if c then
        if started then
          T.ok(gaps[since] ~= nil, "bad gap " .. since)
          gaps[since] = gaps[since] + 1
          total = total + 1
        end
        started = true
        since = 0
      end
    end
    for g = 2, 4 do
      local f = gaps[g] / total
      T.ok(f >= 0.25 and f <= 0.42, "gap " .. g .. " freq " .. f)
    end
  end,

  test_deck_shared_pool = function()
    local rng = seed()
    local d = deck.new(lists(), { soiree = true, bouffe = true }, rng)
    local labels, prefix = {}, { soiree = "s", bouffe = "b" }
    for _ = 1, 600 do
      local w, c = d:next()
      if c then
        labels[c.label] = true
        T.ok(w:sub(1, 1) == prefix[c.id], "word/category mismatch")
      end
    end
    T.ok(labels["Soirée"] and labels["Bouffe"])
  end,

  test_deck_single_word_lists = function()
    local rng = seed()
    local d = deck.new({
      melange = { "a" },
      categories = { { id = "soiree", label = "Soirée", words = { "b" } } },
    }, { soiree = true }, rng)
    for _ = 1, 20 do d:next() end
  end,

  test_deck_empty_melange = function()
    local rng = seed()
    local d = deck.new({
      melange = {},
      categories = { { id = "soiree", label = "Soirée", words = { "b", "c" } } },
    }, { soiree = true }, rng)
    for _ = 1, 20 do
      local w, c = d:next()
      T.ok(w == "b" or w == "c")
      T.eq(c.id, "soiree")
    end
    local e = deck.new({ melange = {}, categories = {} }, {}, rng)
    T.eq(e:next(), nil)
    local e2 = deck.new({ melange = {}, categories = {
      { id = "soiree", label = "Soirée", words = { "b" } } } }, {}, rng)
    T.eq(e2:next(), nil)
  end,

  test_deck_unknown_checked_ignored = function()
    local rng = seed()
    local d = deck.new(lists(), { ["perso:zz"] = true }, rng)
    local w, c = d:next()
    T.ok(w); T.eq(c, nil)
  end,
}
