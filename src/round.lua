-- One round of play: current word and optional countdown. Pure Lua.
local round = {}
round.__index = round

-- seconds: 0 means no timer. on_done(entry) is called when a word leaves the screen.
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

function round:advance(result)
  self:report(result)
  self.word, self.category = self.deck:next()
  if self.word then self.shown = { word = self.word, category = self.category } end
  if not self.started then
    self.started = true
    if self.seconds > 0 then self.remaining = self.seconds end
  end
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
