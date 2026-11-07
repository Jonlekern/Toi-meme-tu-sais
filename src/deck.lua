-- Word deck: shuffled bags plus a hidden die that decides when a
-- category word comes up. Pure Lua; rng(a, b) returns an integer in [a, b].
local seenmod = require("seen")
local deck = {}

local Bag = {}
Bag.__index = Bag

local function shuffle(t, rng)
  for i = #t, 2, -1 do
    local j = rng(1, i)
    t[i], t[j] = t[j], t[i]
  end
end

local function identity(x) return x end

-- seen (optional): memory of shown words; key(item) gives an item's word.
-- Refills put unseen items first, seen ones after; a drawn item is marked
-- and, once every item of the bag is seen, the bag's memory is cleared.
function deck.bag(items, rng, seen, key)
  local self = setmetatable({
    items = items, rng = rng, order = {}, pos = 1, last = nil,
    seen = seen or seenmod.new(), key = key or identity,
  }, Bag)
  self.n = #items
  return self
end

function Bag:keys()
  local ks = {}
  for i = 1, self.n do ks[i] = self.key(self.items[i]) end
  return ks
end

function Bag:refill()
  local fresh, old = {}, {}
  for i = 1, self.n do
    local it = self.items[i]
    local t = self.seen:has(self.key(it)) and old or fresh
    t[#t + 1] = it
  end
  if #fresh == 0 then
    -- everything seen (e.g. the word list changed): start the pile over
    self.seen:reset(self:keys())
    fresh, old = old, {}
  end
  shuffle(fresh, self.rng)
  shuffle(old, self.rng)
  local order = fresh
  for _, it in ipairs(old) do order[#order + 1] = it end
  -- Do not start with the item that just came out.
  if self.n > 1 and self.last ~= nil and order[1] == self.last then
    local j = self.rng(2, self.n)
    order[1], order[j] = order[j], order[1]
  end
  self.order, self.pos = order, 1
end

function Bag:draw()
  if self.n == 0 then return nil end
  if self.pos > #self.order then self:refill() end
  local item = self.order[self.pos]
  self.pos = self.pos + 1
  self.last = item
  self.seen:mark(self.key(item))
  local all = true
  for i = 1, self.n do
    if not self.seen:has(self.key(self.items[i])) then all = false break end
  end
  if all then self.seen:reset(self:keys()) end
  self.seen:changed()
  return item
end

local Deck = {}
Deck.__index = Deck

local function entry_word(e) return e.word end

function deck.new(lists, checked, rng, seen)
  local self = setmetatable({ rng = rng }, Deck)
  seen = seen or seenmod.new()
  self.seen = seen
  self.melange = deck.bag(lists.melange or {}, rng, seen)

  local pool = {}
  for _, cat in ipairs(lists.categories or {}) do
    if checked and checked[cat.id] then
      local category = { id = cat.id, label = cat.label }
      for _, w in ipairs(cat.words) do
        pool[#pool + 1] = { word = w, category = category }
      end
    end
  end
  self.pool = #pool > 0 and deck.bag(pool, rng, seen, entry_word) or nil
  self.hasMelange = #(lists.melange or {}) > 0
  self.wait = rng(2, 4)
  return self
end

-- Identifies the ticked categories (order-independent) so a deck is rebuilt
-- only when they change; false/nil entries do not count.
function deck.signature(checked)
  local ids = {}
  for id, on in pairs(checked or {}) do
    if on then ids[#ids + 1] = id end
  end
  table.sort(ids)
  return table.concat(ids, "\n")
end

-- Returns word, category ({id, label} or nil for melange words);
-- nil when there is nothing to draw.
function Deck:next()
  if self.pool and not self.hasMelange then
    local e = self.pool:draw()
    return e.word, e.category
  end
  if self.pool then
    if self.wait == 1 then
      self.wait = self.rng(2, 4)
      local e = self.pool:draw()
      return e.word, e.category
    end
    self.wait = self.wait - 1
  end
  if not self.hasMelange then return nil end
  return self.melange:draw(), nil
end

return deck
