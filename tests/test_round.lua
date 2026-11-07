local round = require("round")

local function fake_deck()
  return { next = function() return "mot", nil end }
end

return {
  test_round_no_timer = function()
    local r = round.new(fake_deck(), 0)
    r:next()
    T.eq(r:update(999), nil)
    T.eq(r.remaining, nil)
  end,
  test_round_timer = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    T.eq(r:update(29.9), nil)
    T.eq(r:update(0.2), "timeup")
  end,
  test_round_timer_starts_on_first_word = function()
    local r = round.new(fake_deck(), 30)
    T.eq(r:update(100), nil)
  end,
  test_round_next_restarts_timer = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:update(20)
    T.eq(r.remaining, 10)
    r:next()
    T.eq(r.remaining, 30)
  end,
  test_round_skip_restarts_timer = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:update(20)
    r:skip()
    T.eq(r.remaining, 30)
  end,
  test_round_timeup_once_per_word = function()
    local r = round.new(fake_deck(), 5)
    r:next()
    T.eq(r:update(5), "timeup")
    r:next()
    T.eq(r:update(4), nil)
    T.eq(r:update(1), "timeup")
  end,
  test_round_no_reset_without_timer = function()
    local r = round.new(fake_deck(), 0)
    r:next()
    r:next()
    r:skip()
    T.eq(r.remaining, nil)
  end,
  test_round_empty_deck = function()
    local r = round.new({ next = function() return nil end }, 0)
    r:next()
    T.eq(r.word, nil)
  end,
  test_round_results = function()
    local calls = {}
    local deck = { next = function() return "Suçon", { label = "Soirée" } end }
    local r = round.new(deck, 0, function(e) calls[#calls + 1] = e end)
    r:next()
    T.eq(#calls, 0)
    r:next()
    r:skip()
    r:finish()
    T.eq(#calls, 3)
    T.eq(calls[1].result, "suivant")
    T.eq(calls[2].result, "passé")
    T.eq(calls[3].result, "fin")
    T.eq(calls[1].word, "Suçon")
    T.eq(calls[1].category_label, "Soirée")
  end,
  test_round_finish_before_start = function()
    local n = 0
    local r = round.new(fake_deck(), 0, function() n = n + 1 end)
    r:finish()
    T.eq(n, 0)
  end,
  test_round_finish_once = function()
    local n = 0
    local r = round.new(fake_deck(), 0, function() n = n + 1 end)
    r:next()
    r:finish()
    r:finish()
    T.eq(n, 1)
  end,
  test_round_nil_word_no_call = function()
    local n = 0
    local r = round.new({ next = function() return nil end }, 0, function() n = n + 1 end)
    r:next()
    r:next()
    r:finish()
    T.eq(n, 0)
  end,
}
