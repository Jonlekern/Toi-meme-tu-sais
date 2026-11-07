-- One round of play: current word and optional countdown. Pure Lua.
local round = {}
round.__index = round

-- seconds: 0 means no timer. on_done(entry) is called when a word leaves the screen
-- forward (next, skip, finish). Going back with previous() reports nothing: the word
-- left is not counted, and a word shown again is reported again when it leaves.
function round.new(deck, seconds, on_done)
  return setmetatable({
    deck = deck,
    seconds = seconds or 0,
    on_done = on_done,
    word = nil,
    category = nil,
    remaining = nil,
    started = false,
    shown = nil, -- word on screen and its category, if any
    history = {}, -- words shown in this round, in order: { word, category }
    pos = 0, -- index in history of the word on screen (#history + 1: no word)
  }, round)
end

-- Report the displayed word (if any) with a result, once.
function round:report(result)
  local shown = self.shown
  if not shown then return end
  self.shown = nil
  if self.on_done then
    self.on_done({
      word = shown.word,
      category_label = shown.category and shown.category.label or nil,
      result = result,
    })
  end
end

-- Put history entry i on screen (nil entry: no word) and restart the timer.
function round:show(i)
  self.pos = i
  local e = self.history[i]
  self.word, self.category = e and e.word, e and e.category
  self.shown = e and { word = e.word, category = e.category } or nil
  self.started = true
  -- The timer is per word: every new word restarts it from the full duration.
  if self.seconds > 0 then self.remaining = self.seconds end
end

-- Next word: after going back, replay the history before drawing new words
-- (so the deck and its memory of seen words are only used for new ones).
function round:advance(result)
  self:report(result)
  if self.pos < #self.history then return self:show(self.pos + 1) end
  local word, category = self.deck:next()
  if word then
    self.history[#self.history + 1] = { word = word, category = category }
  end
  self:show(#self.history + 1 - (word and 1 or 0))
end

-- Back to the previous word of the round; nothing on the first one.
function round:previous()
  if self.pos <= 1 then return false end
  self:show(self.pos - 1)
  return true
end

function round:next() self:advance("suivant") end

function round:skip() self:advance("passé") end

function round:finish() self:report("fin") end

function round:update(dt)
  if not self.started or not self.remaining then return nil end
  self.remaining = self.remaining - dt
  if self.remaining <= 0 then
    self.remaining = 0
    return "timeup"
  end
  return nil
end

return round
