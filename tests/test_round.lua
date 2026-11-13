local round = require("round")

local function fake_deck()
  return { next = function() return "mot", nil end }
end

-- Deck giving "w1", "w2", ... and counting draws.
local function counting_deck(limit)
  local d = { n = 0 }
  function d.next()
    if limit and d.n >= limit then return nil end
    d.n = d.n + 1
    return "w" .. d.n, { label = "c" .. d.n }
  end
  return d
end

return {
  test_round_pause_stops_the_timer = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:update(10)
    r:pause(true)
    T.eq(r:update(100), nil)
    T.eq(r.remaining, 20)
    r:pause(false)
    r:update(5)
    T.eq(r.remaining, 15)
  end,
  test_round_new_word_unpauses = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:pause(true)
    r:next()
    T.eq(r.paused, false)
  end,
  test_round_restart = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:update(25)
    r:pause(true)
    r:restart()
    T.eq(r.remaining, 30)
    T.eq(r.paused, false)
  end,
  test_round_set_seconds_during_play = function()
    local r = round.new(fake_deck(), 30)
    r:next()
    r:update(10)
    r:set_seconds(90)
    T.eq(r.remaining, 90)
    r:set_seconds(0)
    T.eq(r.remaining, nil)
    T.eq(r:update(999), nil)
    r:set_seconds(60)
    T.eq(r.remaining, 60)
  end,
  test_round_set_seconds_before_first_word = function()
    local r = round.new(fake_deck(), 0)
    r:set_seconds(30)
    T.eq(r:update(100), nil)
    r:next()
    T.eq(r.remaining, 30)
  end,
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
  test_round_previous_on_first_word = function()
    local r = round.new(counting_deck(), 0)
    r:next()
    T.eq(r:previous(), false)
    T.eq(r.word, "w1")
  end,
  test_round_previous_before_start = function()
    local r = round.new(counting_deck(), 0)
    T.eq(r:previous(), false)
    T.eq(r.word, nil)
  end,
  test_round_previous_goes_back = function()
    local d = counting_deck()
    local r = round.new(d, 0)
    r:next(); r:next(); r:skip()
    T.eq(r.word, "w3")
    T.eq(r:previous(), true)
    T.eq(r.word, "w2")
    T.eq(r.category.label, "c2")
    T.eq(r:previous(), true)
    T.eq(r.word, "w1")
    T.eq(r:previous(), false)
    T.eq(d.n, 3) -- going back never draws
  end,
  test_round_forward_replays_history = function()
    local d = counting_deck()
    local r = round.new(d, 0)
    r:next(); r:next(); r:next()
    r:previous(); r:previous()
    r:next()
    T.eq(r.word, "w2")
    r:skip()
    T.eq(r.word, "w3")
    T.eq(d.n, 3)
    r:next()
    T.eq(r.word, "w4") -- history used up: draw again
    T.eq(d.n, 4)
  end,
  test_round_previous_restarts_timer = function()
    local r = round.new(counting_deck(), 30)
    r:next(); r:next()
    r:update(25)
    r:previous()
    T.eq(r.remaining, 30)
  end,
  test_round_previous_reports_nothing = function()
    local calls = {}
    local r = round.new(counting_deck(), 0, function(e) calls[#calls + 1] = e end)
    r:next(); r:next()
    T.eq(#calls, 1)
    r:previous()
    T.eq(#calls, 1) -- w2 left backwards: not reported
    r:next() -- w1 leaves forward again
    T.eq(#calls, 2)
    T.eq(calls[2].word, "w1")
    r:finish()
    T.eq(calls[3].word, "w2")
    T.eq(calls[3].result, "fin")
  end,
  test_round_previous_after_empty_deck = function()
    local r = round.new(counting_deck(2), 0)
    r:next(); r:next(); r:next()
    T.eq(r.word, nil)
    T.eq(r:previous(), true)
    T.eq(r.word, "w2")
    r:next()
    T.eq(r.word, nil)
  end,
}
